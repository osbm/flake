"""WaniKani statistics dashboard — strictly read-only.

Reads the daily archives and hourly snapshots produced by wanikani-sync and
serves a plotly dashboard in three sections: Now (what to do today), Habit
(when and how consistently you study), Progress (level pace against the
December targets, SRS health, leeches). Nothing here writes anywhere.
"""

import functools
import json
import os
import statistics
import sys
import zipfile
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import pandas as pd
import plotly.graph_objects as go
import plotly.io as pio
from flask import Flask, Response

pio.templates.default = "plotly_dark"

app = Flask(__name__)
DATA_DIR = Path(os.environ.get("WANIKANI_LOG_DIR", "/var/lib/wanikani-logs"))

# osbm's clock, not the host's (apollo runs on Europe/Berlin)
LOCAL_TZ = ZoneInfo("Europe/Istanbul")

# the goals this page is measured against
JLPT_DATE = datetime(2026, 12, 6, tzinfo=LOCAL_TZ)  # JLPT N3, December 2026
YEAR_END = datetime(2026, 12, 31, tzinfo=LOCAL_TZ)
TARGET_LEVELS = (28, 30)  # stretch target set July 2026
LEVEL_FLOOR_DAYS = 7  # fastest the SRS allows past level 2
APPRENTICE_BANDS = (100, 150)  # green below, amber between, red above

# WaniKani palette
TYPE_COLORS = {
    "radical": "#00AAFF",
    "kanji": "#FF00AA",
    "vocabulary": "#AA00FF",
    "kana_vocabulary": "#AA00FF",
}
STAGE_COLORS = {
    "Apprentice": "#DD0093",
    "Guru": "#882D9E",
    "Master": "#294DDB",
    "Enlightened": "#0093DD",
    "Burned": "#faaa1e",
}
STAGE_GROUPS = [  # srs_stage ranges
    ("Apprentice", 1, 4),
    ("Guru", 5, 6),
    ("Master", 7, 7),
    ("Enlightened", 8, 8),
]
SRS_STAGE_NAMES = [
    "Unlocked",
    "Apprentice I",
    "Apprentice II",
    "Apprentice III",
    "Apprentice IV",
    "Guru I",
    "Guru II",
    "Master",
    "Enlightened",
    "Burned",
]
WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

BG = "#151519"
CARD_BG = "#1a1a1f"
BORDER = "#26262e"
MUTED = "#77778a"
GOOD = "#3ddc84"
BAD = "#ff5c7a"
WARN = "#f5b942"
ACTIVITY_SCALE = [[0, "#26262e"], [0.25, "#5c2d9e"], [1, "#FF00AA"]]

PLOT_LAYOUT = dict(
    template="plotly_dark",
    plot_bgcolor=CARD_BG,
    paper_bgcolor=CARD_BG,
    height=400,
    margin=dict(l=50, r=30, t=70, b=50),
    legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
    hoverlabel=dict(bgcolor="#2a2a33"),
)
SMALL = 320


def now_local():
    return datetime.now(LOCAL_TZ)


def parse_ts(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00")) if value else None


def stage_group(stage):
    for name, lo, hi in STAGE_GROUPS:
        if lo <= stage <= hi:
            return name
    return None


# --- daily archives ---------------------------------------------------------


def get_snapshots():
    """Daily snapshots: plain directories (current format) or zips (legacy)."""
    return sorted(
        p
        for p in DATA_DIR.glob("wanikani_data_*")
        if p.is_dir() or (p.is_file() and p.suffix == ".zip")
    )


def snapshot_date(snapshot):
    return snapshot.name.removeprefix("wanikani_data_").removesuffix(".zip")


def read_json(snapshot, name):
    if snapshot.is_dir():
        path = snapshot / name
        if not path.is_file():
            return None
        with open(path) as f:
            return json.load(f)
    with zipfile.ZipFile(snapshot, "r") as z:
        if name not in z.namelist():
            return None
        with z.open(name) as f:
            return json.load(f)


def is_leech(stat, stage):
    """An item that keeps failing and is still in rotation."""
    wrong = stat["meaning_incorrect"] + stat["reading_incorrect"]
    return (
        wrong >= 2
        and stat["percentage_correct"] < 75
        and 1 <= stage <= 8
        and not stat.get("hidden")
    )


@functools.lru_cache(maxsize=None)
def load_snapshot_timeseries(snapshot):
    """Per-day numbers used by the time-series charts (cached per snapshot)."""
    data = {"date": snapshot_date(snapshot)}

    summary = read_json(snapshot, "summary.json")
    data["num_reviews"] = len(summary["data"]["reviews"][0]["subject_ids"])
    data["num_lessons"] = len(summary["data"]["lessons"][0]["subject_ids"])

    assignments = read_json(snapshot, "assignments.json")
    srs_stages = [0] * 10
    stage_of = {}
    for assignment in assignments["data"]:
        stage = assignment["data"]["srs_stage"]
        srs_stages[stage] += 1
        stage_of[assignment["data"]["subject_id"]] = stage
    for i, count in enumerate(srs_stages):
        data[f"srs_stage_{i}"] = count

    stats = read_json(snapshot, "review_statistics.json")
    data["leeches"] = (
        sum(
            1
            for s in stats["data"]
            if is_leech(s["data"], stage_of.get(s["data"]["subject_id"], 0))
        )
        if stats
        else None
    )
    return data


@functools.lru_cache(maxsize=4)
def load_details(snapshot):
    """Detail data (only needed from the newest snapshot)."""
    return {
        "user": read_json(snapshot, "user.json"),
        "summary": read_json(snapshot, "summary.json"),
        "level_progressions": read_json(snapshot, "level_progressions.json"),
        "review_statistics": read_json(snapshot, "review_statistics.json"),
        "assignments": read_json(snapshot, "assignments.json"),
    }


@functools.lru_cache(maxsize=2)
def load_subjects(cache_key):
    """subject_id -> {characters, level, type}. cache_key busts on file change."""
    standalone = DATA_DIR / "subjects.json"
    subjects = None
    if standalone.is_file():
        with open(standalone) as f:
            subjects = json.load(f)
    else:
        for snapshot in reversed(get_snapshots()):
            subjects = read_json(snapshot, "subjects.json")
            if subjects is not None:
                break
    if subjects is None:
        return {}, 0

    id_map = {}
    active = 0
    for subj in subjects["data"]:
        if not subj["data"].get("hidden_at"):
            active += 1
        id_map[subj["id"]] = {
            "characters": subj["data"].get("characters") or subj["data"].get("slug"),
            "level": subj["data"]["level"],
            "type": subj["object"],
            "url": subj["data"].get("document_url"),
        }
    return id_map, active


def subjects_cache_key():
    standalone = DATA_DIR / "subjects.json"
    if standalone.is_file():
        return f"standalone:{standalone.stat().st_mtime_ns}"
    files = get_snapshots()
    return f"zip:{files[-1].name}" if files else "none"


def get_dataframe():
    df = pd.DataFrame(load_snapshot_timeseries(p) for p in get_snapshots())
    df.sort_values(by="date", inplace=True)
    df["apprentice"] = sum(df[f"srs_stage_{i}"] for i in range(1, 5))
    df["guru"] = df["srs_stage_5"] + df["srs_stage_6"]
    df["master"] = df["srs_stage_7"]
    df["enlightened"] = df["srs_stage_8"]
    df["burned"] = df["srs_stage_9"]
    _, total_subjects = load_subjects(subjects_cache_key())
    total_subjects = total_subjects or 9300  # last resort if no subjects source exists
    df["progression"] = (
        sum(df[f"srs_stage_{i}"] * (i + 1) for i in range(10)) / (total_subjects * 10) * 100
    )
    return df


# --- hourly snapshots (wanikani-sync, since 2026-09) -----------------------
#
# hourly/YYYY-MM-DD/HH.json (UTC): a tiny "unchanged" stub for idle hours, a
# full assignments+review_statistics dump for hours with activity. Diffing
# two consecutive full snapshots yields exactly what happened in between —
# per-session data the WK API no longer offers (its reviews endpoint is dead).


def hourly_files():
    hourly_dir = DATA_DIR / "hourly"
    return sorted(hourly_dir.glob("*/*.json")) if hourly_dir.is_dir() else []


@functools.lru_cache(maxsize=8)
def load_hourly_raw(path):
    with open(path) as f:
        return json.load(f)


@functools.lru_cache(maxsize=None)
def load_hourly_meta(path):
    """Per-file facts, small enough to cache forever."""
    try:
        d = load_hourly_raw(path)
    except (json.JSONDecodeError, OSError):
        return None  # 0-byte / partial leftovers from failed runs
    summary = d.get("summary") or {}
    time = parse_ts(d["fetched_at"]).astimezone(LOCAL_TZ)
    return {
        "time": time,
        # the timer fires at HH:15, so this snapshot describes what happened
        # between (HH-1):15 and HH:15 — bucket it as hour HH-1, the one it
        # mostly covers (and the one you'd name if asked "when did I review")
        "slot": (time - timedelta(hours=1)).replace(minute=0, second=0, microsecond=0),
        "unchanged": d.get("unchanged", True),
        "reviews_pending": summary.get("reviews_pending"),
        "lessons_pending": summary.get("lessons_pending"),
    }


@functools.lru_cache(maxsize=None)
def hourly_delta(prev_path, cur_path):
    """What happened between two consecutive full snapshots (cached: the
    2MB payloads are parsed once per pair, only these counters are kept)."""
    prev, cur = load_hourly_raw(prev_path), load_hourly_raw(cur_path)

    def answers(d):
        return {
            s["data"]["subject_id"]: (
                s["data"]["meaning_correct"] + s["data"]["reading_correct"],
                s["data"]["meaning_incorrect"] + s["data"]["reading_incorrect"],
            )
            for s in d["review_statistics"]["data"]
        }

    def stages(d):
        return {
            a["data"]["subject_id"]: a["data"]["srs_stage"]
            for a in d["assignments"]["data"]
        }

    prev_st, cur_st = stages(prev), stages(cur)

    # review_statistics count *answers*: meaning and reading separately,
    # plus every retry. A kanji reviewed once contributes 2 correct answers
    # (and 1+ incorrect if missed first), so summed answers run at 2-3x the
    # number of items WaniKani shows for the session. Count items too, and
    # bucket first-try success by the SRS stage the item was reviewed at.
    prev_ans, cur_ans = answers(prev), answers(cur)
    correct = incorrect = items = items_clean = 0
    by_stage = {name: [0, 0] for name, _, _ in STAGE_GROUPS}  # [items, clean]
    for sid, (c, i) in cur_ans.items():
        pc, pi = prev_ans.get(sid, (0, 0))
        dc, di = max(0, c - pc), max(0, i - pi)
        correct += dc
        incorrect += di
        if dc or di:
            items += 1
            items_clean += 1 if di == 0 else 0
            group = stage_group(prev_st.get(sid, 0))
            if group:
                by_stage[group][0] += 1
                by_stage[group][1] += 1 if di == 0 else 0

    lessons = promoted = demoted = 0
    for sid, stage in cur_st.items():
        old = prev_st.get(sid, 0)  # new assignments unlock at stage 0
        if old == 0:
            lessons += 1 if stage >= 1 else 0
        elif stage > old:
            promoted += 1
        elif stage < old:
            demoted += 1

    return {
        "items": items,  # subjects reviewed (what WK calls "reviews")
        "items_clean": items_clean,  # ...answered right first time
        "answers": correct + incorrect,
        "correct": correct,
        "incorrect": incorrect,
        "lessons": lessons,
        "promoted": promoted,
        "demoted": demoted,
        "by_stage": by_stage,
    }


def get_hourly_data():
    """(all metas, full-snapshot metas, per-active-hour deltas)."""
    metas = [
        (p, m) for p in hourly_files() if (m := load_hourly_meta(p)) is not None
    ]
    fulls = [(p, m) for p, m in metas if not m["unchanged"]]
    # intervening stubs prove nothing happened between two fulls, so the
    # whole diff belongs to the later snapshot's hour. The first full ever
    # (and the first after the account un-hibernated) is only a baseline.
    deltas = [
        {"time": cur_m["time"], "slot": cur_m["slot"], **hourly_delta(prev_p, cur_p)}
        for (prev_p, _), (cur_p, cur_m) in zip(fulls, fulls[1:])
    ]
    return [m for _, m in metas], [m for _, m in fulls], deltas


# --- analysis ---------------------------------------------------------------


def day_activity(metas, deltas):
    """date -> items+lessons that day; days covered by any snapshot count
    as 0, days before the hourly archive started are absent (unknown)."""
    days = {m["slot"].date(): 0 for m in metas}
    for d in deltas:
        days[d["slot"].date()] = days.get(d["slot"].date(), 0) + d["items"] + d["lessons"]
    return days


def streaks(days, today):
    active = {d for d, n in days.items() if n > 0}
    start = today if today in active else today - timedelta(days=1)
    streak = 0
    while start - timedelta(days=streak) in active:
        streak += 1
    last30 = sum(1 for i in range(30) if today - timedelta(days=i) in active)
    return streak, last30


def window_accuracy(deltas, start, end):
    """(items, first-try %) for sessions whose slot falls in [start, end)."""
    items = clean = 0
    for d in deltas:
        if start <= d["slot"] < end:
            items += d["items"]
            clean += d["items_clean"]
    return items, (100 * clean / items if items else None)


def backlog_projection(fulls, now, days=14):
    """Linear trend of reviews pending (measured after each active hour)
    over the last `days`; where it hits zero if it is falling."""
    points = [
        (m["time"], m["reviews_pending"])
        for m in fulls
        if m["reviews_pending"] is not None and m["time"] >= now - timedelta(days=days)
    ]
    if len(points) < 4:
        return None
    t0 = points[0][0]
    xs = [(t - t0).total_seconds() / 86400 for t, _ in points]
    ys = [y for _, y in points]
    mx, my = sum(xs) / len(xs), sum(ys) / len(ys)
    var = sum((x - mx) ** 2 for x in xs)
    if var == 0:
        return None
    slope = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / var  # per day
    current = points[-1][1]
    clear_at = None
    if slope < -0.5 and current > 0:
        clear_at = points[-1][0] + timedelta(days=current / -slope)
    return {"slope": slope, "current": current, "clear_at": clear_at, "start": t0}


def level_history(details, now):
    rows = []
    for lp in details["level_progressions"]["data"]:
        d = lp["data"]
        unlocked = parse_ts(d.get("unlocked_at"))
        if unlocked is None:
            continue
        rows.append(
            {
                "level": d["level"],
                "unlocked": unlocked.astimezone(LOCAL_TZ),
                "passed": (parse_ts(d["passed_at"]).astimezone(LOCAL_TZ) if d.get("passed_at") else None),
                "abandoned": bool(d.get("abandoned_at")),
            }
        )
    rows.sort(key=lambda r: r["unlocked"])
    for r in rows:
        end = r["passed"] or (None if r["abandoned"] else now)
        r["days"] = (end - r["unlocked"]).total_seconds() / 86400 if end else None
    return rows


def level_projection(rows, now):
    current = next((r for r in reversed(rows) if r["passed"] is None and not r["abandoned"]), None)
    completed = [r["days"] for r in rows if r["passed"] is not None and not r["abandoned"]]
    if current is None or not completed:
        return None
    pace = statistics.median(completed[-5:])
    days_on_level = current["days"]

    def project(per_level, target):
        horizon = (target - now).total_seconds() / 86400
        if horizon <= 0:
            return current["level"]
        first = max(per_level - days_on_level, 0)  # rest of the current level
        if horizon < first:
            return current["level"]
        return current["level"] + 1 + int((horizon - first) // per_level)

    return {
        "level": current["level"],
        "unlocked": current["unlocked"],
        "days_on_level": days_on_level,
        "pace": pace,
        "jlpt_pace": project(pace, JLPT_DATE),
        "jlpt_floor": project(LEVEL_FLOOR_DAYS, JLPT_DATE),
        "year_pace": project(pace, YEAR_END),
        "year_floor": project(LEVEL_FLOOR_DAYS, YEAR_END),
    }


# --- figures ----------------------------------------------------------------


def date_axis(fig, end=None, default_days=None):
    """Range buttons on a date axis, optionally zoomed to the last N days."""
    fig.update_xaxes(
        type="date",
        rangeselector=dict(
            buttons=[
                dict(count=7, label="7d", step="day", stepmode="backward"),
                dict(count=1, label="1m", step="month", stepmode="backward"),
                dict(count=3, label="3m", step="month", stepmode="backward"),
                dict(count=1, label="1y", step="year", stepmode="backward"),
                dict(step="all", label="all"),
            ],
            bgcolor=BORDER,
            activecolor="#3a3a48",
            font=dict(color="#ddd", size=11),
            x=0,
            y=1.02,
            yanchor="bottom",
        ),
    )
    # the buttons sit where the legend normally goes: legend moves below
    fig.update_layout(
        legend=dict(y=-0.18, yanchor="top", x=0, xanchor="left"),
        margin=dict(b=85),
    )
    if end is not None and default_days:
        fig.update_xaxes(range=[end - timedelta(days=default_days), end])


def vline(fig, x, label, color=MUTED):
    fig.add_shape(
        type="line", x0=x, x1=x, y0=0, y1=1, yref="paper",
        line=dict(color=color, width=1, dash="dot"),
    )
    fig.add_annotation(
        x=x, y=1, yref="paper", text=label, showarrow=False,
        yanchor="bottom", font=dict(size=11, color=color),
    )


def fig_backlog(fulls, proj, now):
    points = [m for m in fulls if m["reviews_pending"] is not None]
    if len(points) < 2:
        return None
    fig = go.Figure()
    fig.add_trace(
        go.Scatter(
            x=[m["time"] for m in points],
            y=[m["reviews_pending"] for m in points],
            mode="lines+markers",
            name="Reviews pending",
            line=dict(width=2, color="#00AAFF"),
            marker=dict(size=4),
        )
    )
    fig.add_trace(
        go.Scatter(
            x=[m["time"] for m in points],
            y=[m["lessons_pending"] for m in points],
            mode="lines",
            name="Lessons pending",
            line=dict(width=1.5, color="#FF00AA"),
        )
    )
    title = "Backlog"
    if proj:
        last = points[-1]
        horizon = proj["clear_at"] or now + timedelta(days=30)
        horizon = min(horizon, now + timedelta(days=60))
        days_ahead = (horizon - last["time"]).total_seconds() / 86400
        fig.add_trace(
            go.Scatter(
                x=[last["time"], horizon],
                y=[last["reviews_pending"], max(0, last["reviews_pending"] + proj["slope"] * days_ahead)],
                mode="lines",
                name="14-day trend",
                line=dict(width=1.5, color="#faaa1e", dash="dash"),
            )
        )
        if proj["clear_at"]:
            title = f"Backlog — clears around {proj['clear_at']:%b %d} at this pace ({proj['slope']:+.0f}/day)"
        elif proj["slope"] > 0.5:
            title = f"Backlog — growing {proj['slope']:+.0f}/day over the last 14 days"
        else:
            title = "Backlog — flat over the last 14 days"
    fig.update_layout(title=title, yaxis_title="Items", **{**PLOT_LAYOUT, "height": SMALL + 40})
    date_axis(fig, end=now + timedelta(days=3), default_days=30)
    return fig


def fig_forecast(details):
    buckets = details["summary"]["data"]["reviews"][1:]
    if not buckets:
        return None
    times = [parse_ts(b["available_at"]).astimezone(LOCAL_TZ) for b in buckets]
    fig = go.Figure(
        go.Bar(
            x=times,
            y=[len(b["subject_ids"]) for b in buckets],
            marker_color="#00AAFF",
            width=3600 * 1000 * 0.8,
            hovertemplate="%{x|%a %H:%M} — %{y} unlock<extra></extra>",
        )
    )
    total = sum(len(b["subject_ids"]) for b in buckets)
    fig.update_layout(
        title=f"Unlocking in the next 24h — {total} items (from the nightly archive)",
        yaxis_title="Reviews",
        **{**PLOT_LAYOUT, "height": SMALL + 40},
    )
    fig.update_xaxes(type="date", tickformat="%H:%M")
    return fig


def fig_calendar(days, today, weeks=12):
    """GitHub-style: one cell per day, last `weeks` weeks, Monday rows."""
    monday = today - timedelta(days=today.weekday())
    first = monday - timedelta(weeks=weeks - 1)
    z, text = [], []
    for wd in range(7):
        row, trow = [], []
        for w in range(weeks):
            day = first + timedelta(weeks=w, days=wd)
            if day > today or day not in days:
                row.append(None)
                trow.append("")
            else:
                row.append(days[day])
                trow.append(f"{day:%a %b %d} — {days[day]} items")
        z.append(row)
        text.append(trow)
    x = [(first + timedelta(weeks=w)).strftime("%b %d") for w in range(weeks)]
    fig = go.Figure(
        go.Heatmap(
            x=x,
            y=WEEKDAYS,
            z=z,
            text=text,
            hovertemplate="%{text}<extra></extra>",
            colorscale=ACTIVITY_SCALE,
            xgap=3,
            ygap=3,
            showscale=False,
            zmin=0,
        )
    )
    fig.update_layout(
        title=f"Consistency — reviews + lessons per day, last {weeks} weeks",
        **{**PLOT_LAYOUT, "height": 290, "margin": dict(l=50, r=30, t=60, b=40)},
    )
    fig.update_xaxes(side="bottom", tickangle=0, title="week of")
    fig.update_yaxes(autorange="reversed")
    return fig


def fig_hourly_grid(metas, deltas, today, days=28):
    """Day x hour counter: items per hour slot, last `days` days."""
    first = today - timedelta(days=days - 1)
    by_slot = {}
    for m in metas:  # every snapshot (stub or full) proves the hour was idle
        if m["slot"].date() >= first:
            by_slot[(m["slot"].date(), m["slot"].hour)] = 0
    for d in deltas:  # ...unless a delta says otherwise
        key = (d["slot"].date(), d["slot"].hour)
        if key in by_slot:
            by_slot[key] = d["items"] + d["lessons"]
    if not by_slot:
        return None
    dates = [first + timedelta(days=i) for i in range(days)]
    z = [[by_slot.get((day, h)) for h in range(24)] for day in dates]
    totals = [sum(v for v in row if v) for row in z]
    fig = go.Figure(
        go.Heatmap(
            x=list(range(24)),
            y=[f"{day:%a %b %d}" for day in dates],
            z=z,
            colorscale=ACTIVITY_SCALE,
            xgap=2,
            ygap=2,
            hovertemplate="%{y} %{x}:00 — %{z} items<extra></extra>",
            showscale=False,  # the row totals at right replace the colour bar
            zmin=0,
        )
    )
    for label, total in zip([f"{day:%a %b %d}" for day in dates], totals):
        fig.add_annotation(
            xref="paper", x=1.005, y=label, text=str(total) if total else "",
            showarrow=False, xanchor="left", font=dict(size=10, color=MUTED),
        )
    fig.update_layout(
        title=f"Hourly counter — items per hour, last {days} days (row total at right)",
        xaxis_title=f"Hour of day ({LOCAL_TZ.key})",
        **{**PLOT_LAYOUT, "height": 110 + 19 * days, "margin": dict(l=90, r=70, t=60, b=50)},
    )
    fig.update_xaxes(dtick=1)
    fig.update_yaxes(autorange="reversed", type="category")
    return fig


def fig_profile(deltas, today, weeks=8):
    """Weekday x hour: average items per week in each slot."""
    start = today - timedelta(weeks=weeks)
    grid = [[0] * 24 for _ in range(7)]
    for d in deltas:
        if d["slot"].date() >= start:
            grid[d["slot"].weekday()][d["slot"].hour] += d["items"] + d["lessons"]
    if not any(any(row) for row in grid):
        return None
    z = [[round(v / weeks, 1) for v in row] for row in grid]
    fig = go.Figure(
        go.Heatmap(
            x=list(range(24)),
            y=WEEKDAYS,
            z=z,
            colorscale=ACTIVITY_SCALE,
            xgap=2,
            ygap=2,
            hovertemplate="%{y} %{x}:00 — %{z} items/week<extra></extra>",
            colorbar=dict(title="items/wk", thickness=12),
            zmin=0,
        )
    )
    fig.update_layout(
        title=f"When you actually study — average items per hour slot, last {weeks} weeks",
        xaxis_title=f"Hour of day ({LOCAL_TZ.key})",
        **{**PLOT_LAYOUT, "height": 300, "margin": dict(l=50, r=30, t=60, b=50)},
    )
    fig.update_xaxes(dtick=1)
    fig.update_yaxes(autorange="reversed")
    return fig


def fig_sessions(deltas, now):
    sessions = [d for d in deltas if d["items"] > 0]
    if not sessions:
        return None
    x = [d["slot"] + timedelta(minutes=30) for d in sessions]
    fig = go.Figure()
    fig.add_trace(
        go.Bar(
            x=x,
            y=[d["items"] for d in sessions],
            name="Reviews",
            marker_color="#294DDB",
            width=3600 * 1000 * 0.8,  # hour-wide bars on a ms date axis
            customdata=[[d["answers"], d["incorrect"]] for d in sessions],
            hovertemplate="%{y} reviews<br>%{customdata[0]} answers, "
            "%{customdata[1]} wrong<extra></extra>",
        )
    )
    fig.add_trace(
        go.Scatter(
            x=x,
            y=[100 * d["items_clean"] / d["items"] for d in sessions],
            mode="markers",
            name="Right first try %",
            yaxis="y2",
            line=dict(width=2, color="#faaa1e"),
            marker=dict(size=6),
        )
    )
    fig.update_layout(
        title="Sessions — volume and first-try accuracy per active hour",
        yaxis_title="Reviews (items)",
        yaxis2=dict(title="Accuracy (%)", overlaying="y", side="right", range=[0, 100], showgrid=False),
        **PLOT_LAYOUT,
    )
    date_axis(fig, end=now + timedelta(hours=6), default_days=14)
    return fig


def fig_srs_flow(deltas, now):
    sessions = [d for d in deltas if d["promoted"] or d["demoted"] or d["lessons"]]
    if not sessions:
        return None
    x = [d["slot"] + timedelta(minutes=30) for d in sessions]
    bar_width = 3600 * 1000 * 0.8
    fig = go.Figure()
    for key, name, color, sign in [
        ("promoted", "Promoted", "#0093DD", 1),
        ("lessons", "New lessons", "#faaa1e", 1),
        ("demoted", "Demoted", "#DD0093", -1),
    ]:
        fig.add_trace(
            go.Bar(x=x, y=[sign * d[key] for d in sessions], name=name, marker_color=color, width=bar_width)
        )
    fig.update_layout(
        title="SRS flow per session — demotions below zero are leech pressure",
        yaxis_title="Items",
        barmode="relative",
        **PLOT_LAYOUT,
    )
    date_axis(fig, end=now + timedelta(hours=6), default_days=14)
    return fig


def fig_level_path(rows, proj, now):
    if not rows:
        return None
    x, y = [], []
    for r in rows:
        x.append(r["unlocked"])
        y.append(r["level"])
    x.append(now)
    y.append(y[-1])
    fig = go.Figure()
    fig.add_trace(
        go.Scatter(x=x, y=y, mode="lines", name="Level", line=dict(shape="hv", width=2.5, color="#882D9E"))
    )
    title = "Level over time"
    if proj:
        for per_level, name, color in [
            (proj["pace"], f"your pace ({proj['pace']:.0f} d/level)", "#faaa1e"),
            (LEVEL_FLOOR_DAYS, f"SRS floor ({LEVEL_FLOOR_DAYS} d/level)", "#3ddc84"),
        ]:
            px, py = [now], [proj["level"]]
            t = now + timedelta(days=max(per_level - proj["days_on_level"], 0))
            level = proj["level"]
            while t <= YEAR_END + timedelta(days=1):
                level += 1
                px.append(t)
                py.append(level)
                t += timedelta(days=per_level)
            px.append(YEAR_END)
            py.append(py[-1])
            fig.add_trace(
                go.Scatter(x=px, y=py, mode="lines", name=name, line=dict(shape="hv", width=1.5, dash="dash", color=color))
            )
        fig.add_shape(
            type="rect", xref="paper", x0=0, x1=1, y0=TARGET_LEVELS[0], y1=TARGET_LEVELS[1],
            fillcolor="rgba(61, 220, 132, 0.10)", line=dict(width=0), layer="below",
        )
        fig.add_annotation(
            xref="paper", x=0.01, y=TARGET_LEVELS[1], text=f"target {TARGET_LEVELS[0]}–{TARGET_LEVELS[1]} (set July)",
            showarrow=False, yanchor="bottom", xanchor="left", font=dict(size=11, color=GOOD),
        )
        title = (
            f"Level {proj['level']} → ~{proj['jlpt_pace']} by the JLPT at your pace "
            f"({proj['jlpt_floor']} at the floor), and ~{proj['year_pace']} by year end ({proj['year_floor']} at the floor)"
        )
    vline(fig, JLPT_DATE, "JLPT")
    vline(fig, YEAR_END, "2026")
    fig.update_layout(title=title, yaxis_title="Level", **PLOT_LAYOUT)
    date_axis(fig, end=YEAR_END + timedelta(days=10), default_days=365)
    return fig


def fig_level_days(rows, proj):
    rows = [r for r in rows if r["days"] is not None]
    if not rows:
        return None
    # a level that appears twice (reset) gets the year on both bars
    seen = {}
    for r in rows:
        seen[r["level"]] = seen.get(r["level"], 0) + 1
    dupes = {lvl for lvl, n in seen.items() if n > 1}
    labels = [
        f"{r['level']} ('{r['unlocked']:%y})" if r["level"] in dupes else str(r["level"]) for r in rows
    ]
    fig = go.Figure(
        go.Bar(
            x=labels,
            y=[r["days"] for r in rows],
            marker_color=["#4a4a55" if r["passed"] is None else "#882D9E" for r in rows],
            hovertemplate="level %{x}: %{y:.0f} days<extra></extra>",
        )
    )
    if proj:
        fig.add_hline(y=proj["pace"], line=dict(color="#faaa1e", width=1, dash="dash"),
                      annotation_text=f"median of last 5: {proj['pace']:.0f} d", annotation_position="top left",
                      annotation_font=dict(size=11, color="#faaa1e"))
    fig.add_hline(y=LEVEL_FLOOR_DAYS, line=dict(color="#3ddc84", width=1, dash="dot"))
    fig.update_layout(
        title="Days per level (grey = current, still in progress)",
        xaxis_title="Level",
        yaxis_title="Days",
        **{**PLOT_LAYOUT, "height": SMALL + 40},
    )
    fig.update_xaxes(type="category")
    return fig


def fig_srs_composition(df, now):
    fig = go.Figure()
    for column, name in [
        ("apprentice", "Apprentice"),
        ("guru", "Guru"),
        ("master", "Master"),
        ("enlightened", "Enlightened"),
        ("burned", "Burned"),
    ]:
        fig.add_trace(
            go.Scatter(
                x=df["date"], y=df[column], mode="lines", name=name, stackgroup="one",
                line=dict(width=0.5, color=STAGE_COLORS[name]),
                hovertemplate="%{y} " + name.lower() + "<extra></extra>",
            )
        )
    fig.update_layout(title="SRS stage composition", yaxis_title="Items", hovermode="x unified", **PLOT_LAYOUT)
    date_axis(fig, end=now, default_days=365)
    return fig


def fig_progression(df, now):
    latest = df.iloc[-1]["progression"]
    fig = go.Figure(
        go.Scatter(
            x=df["date"], y=df["progression"], mode="lines", name="Progression",
            line=dict(width=2.5, color="#faaa1e"), fill="tozeroy", fillcolor="rgba(250, 170, 30, 0.15)",
            hovertemplate="%{y:.4f}%<extra></extra>",
        )
    )
    fig.update_layout(
        title=f"Overall progression — {latest:.4f}% (100% means every item is burned)",
        yaxis_title="Progression (%)",
        showlegend=False,
        **{**PLOT_LAYOUT, "height": SMALL + 40},
    )
    date_axis(fig, end=now, default_days=365)
    return fig


def fig_stage_accuracy(deltas, now, days=30):
    """First-try accuracy by the stage an item was reviewed at: last 30 days
    vs the 30 before. Low Guru = lessons too fast; low Master = structural."""
    windows = [
        (f"last {days} days", now - timedelta(days=days), now, "#faaa1e"),
        (f"{days} days before", now - timedelta(days=2 * days), now - timedelta(days=days), "#4a4a55"),
    ]
    fig = go.Figure()
    any_data = False
    for name, start, end, color in windows:
        totals = {g: [0, 0] for g, _, _ in STAGE_GROUPS}
        for d in deltas:
            if start <= d["slot"] < end:
                for g, (n, clean) in d["by_stage"].items():
                    totals[g][0] += n
                    totals[g][1] += clean
        ys = [100 * c / n if n else None for n, c in totals.values()]
        any_data = any_data or any(y is not None for y in ys)
        fig.add_trace(
            go.Bar(
                x=list(totals),
                y=ys,
                name=name,
                marker_color=color,
                customdata=[n for n, _ in totals.values()],
                hovertemplate="%{x}: %{y:.0f}% right first try<br>%{customdata} reviews<extra></extra>",
                text=[f"{y:.0f}%" if y is not None else "" for y in ys],
                textposition="outside",
            )
        )
    if not any_data:
        return None
    fig.update_layout(
        title="First-try accuracy by SRS stage",
        yaxis_title="Right first try (%)",
        yaxis_range=[0, 118],
        barmode="group",
        **{**PLOT_LAYOUT, "height": SMALL + 40},
    )
    return fig


def fig_leech_trend(df, now):
    series = df.dropna(subset=["leeches"])
    if series.empty:
        return None
    fig = go.Figure(
        go.Scatter(
            x=series["date"], y=series["leeches"], mode="lines", name="Leeches",
            line=dict(width=2, color="#DD0093"), fill="tozeroy", fillcolor="rgba(221, 0, 147, 0.12)",
        )
    )
    fig.update_layout(
        title="Leeches — items under 75% accuracy with 2+ misses, not burned",
        yaxis_title="Items",
        **{**PLOT_LAYOUT, "height": SMALL + 40},
    )
    date_axis(fig, end=now, default_days=180)
    return fig


def fig_accuracy_hist(details):
    stats = details["review_statistics"]["data"]
    fig = go.Figure()
    for subject_type in ["radical", "kanji", "vocabulary"]:
        values = [
            s["data"]["percentage_correct"]
            for s in stats
            if s["data"]["subject_type"].startswith(subject_type) and not s["data"].get("hidden")
        ]
        if values:
            fig.add_trace(
                go.Histogram(
                    x=values, name=subject_type, xbins=dict(start=0, end=101, size=5),
                    marker_color=TYPE_COLORS[subject_type], opacity=0.85,
                )
            )
    fig.update_layout(
        title="Lifetime accuracy distribution",
        xaxis_title="Percentage correct",
        yaxis_title="Items",
        barmode="stack",
        **{**PLOT_LAYOUT, "height": SMALL + 40},
    )
    return fig


# --- html pieces ------------------------------------------------------------


def leech_table_html(details):
    id_map, _ = load_subjects(subjects_cache_key())
    if not id_map:
        return "<p>subjects.json not available yet — leech table needs it.</p>"

    srs_by_subject = {a["data"]["subject_id"]: a["data"]["srs_stage"] for a in details["assignments"]["data"]}
    leeches = []
    for s in details["review_statistics"]["data"]:
        d = s["data"]
        wrong = d["meaning_incorrect"] + d["reading_incorrect"]
        stage = srs_by_subject.get(d["subject_id"], 0)
        subj = id_map.get(d["subject_id"])
        if wrong < 2 or d.get("hidden") or stage == 9 or subj is None:
            continue
        leeches.append(
            {
                "characters": subj["characters"],
                "type": d["subject_type"],
                "level": subj["level"],
                "stage": SRS_STAGE_NAMES[stage],
                "accuracy": d["percentage_correct"],
                "wrong": wrong,
                "url": subj.get("url") or "#",
            }
        )
    leeches.sort(key=lambda x: (x["accuracy"], -x["wrong"]))
    rows = "".join(
        f"""<tr>
            <td class="item"><a href="{l["url"]}" target="_blank" rel="noopener"
                style="color: {TYPE_COLORS.get(l["type"], "#fff")}"
                >{l["characters"]}</a></td>
            <td>{l["type"].replace("_", " ")}</td>
            <td class="num">{l["level"]}</td>
            <td>{l["stage"]}</td>
            <td class="num">{l["accuracy"]}%</td>
            <td class="num">{l["wrong"]}</td>
        </tr>"""
        for l in leeches[:20]
    )
    return f"""
    <h3>Your 20 most-missed items</h3>
    <div class="table-wrap"><table>
        <thead><tr>
            <th>Item</th><th>Type</th><th class="num">Level</th><th>SRS stage</th>
            <th class="num">Accuracy</th><th class="num">Times wrong</th>
        </tr></thead>
        <tbody>{rows}</tbody>
    </table></div>
    """


def card_html(value, label, delta=None, good=None, note=None, band=None, fmt="{:+d}"):
    """good: 'up' or 'down' — which direction of the delta is progress."""
    sub = ""
    if delta is not None:
        if delta == 0 or good is None:
            color = MUTED
        else:
            improving = (delta > 0) == (good == "up")
            color = GOOD if improving else BAD
        sub = f'<div class="card-delta" style="color:{color}">{fmt.format(delta)} vs 7d ago</div>'
    elif note:
        sub = f'<div class="card-delta">{note}</div>'
    # band = (color, text): the state is spelled out, colour only reinforces it
    if band:
        sub += f'<div class="card-delta" style="color:{band[0]}">{band[1]}</div>'
    return (
        f'<div class="card"><div class="card-value">{value}</div>'
        f'<div class="card-label">{label}</div>{sub}</div>'
    )


def build_cards(df, details, fulls, deltas, days, now):
    today = now.date()
    latest = df.iloc[-1]
    week_ago_rows = df[df["date"] <= (today - timedelta(days=7)).isoformat()]
    week_ago = week_ago_rows.iloc[-1] if not week_ago_rows.empty else None

    def daily_delta(col):
        return int(latest[col] - week_ago[col]) if week_ago is not None else None

    user = details["user"]["data"]
    rows = level_history(details, now)
    proj = level_projection(rows, now)

    pending = [m for m in fulls if m["reviews_pending"] is not None]
    cur = pending[-1] if pending else None
    old = next((m for m in reversed(pending) if m["time"] <= now - timedelta(days=7)), None)

    items7, acc7 = window_accuracy(deltas, now - timedelta(days=7), now)
    items14, acc14 = window_accuracy(deltas, now - timedelta(days=14), now - timedelta(days=7))
    streak, last30 = streaks(days, today)

    apprentice = int(latest["apprentice"])
    if apprentice < APPRENTICE_BANDS[0]:
        band = (GOOD, f"healthy, under {APPRENTICE_BANDS[0]}")
    elif apprentice <= APPRENTICE_BANDS[1]:
        band = (WARN, f"heavy, {APPRENTICE_BANDS[0]}–{APPRENTICE_BANDS[1]}")
    else:
        band = (BAD, f"overloaded, over {APPRENTICE_BANDS[1]}")

    cards = [
        card_html(
            f"Level {user['level']}",
            user["username"],
            note=f"day {proj['days_on_level']:.0f} on this level" if proj else None,
        ),
        card_html(
            cur["reviews_pending"] if cur else int(latest["num_reviews"]),
            "reviews pending",
            delta=(cur["reviews_pending"] - old["reviews_pending"]) if cur and old else None,
            good="down",
        ),
        card_html(
            cur["lessons_pending"] if cur else int(latest["num_lessons"]),
            "lessons pending",
            delta=(cur["lessons_pending"] - old["lessons_pending"]) if cur and old else None,
            good="down",
        ),
        card_html(apprentice, "apprentice", delta=daily_delta("apprentice"), good="down", band=band),
        card_html(int(latest["guru"]), "guru", delta=daily_delta("guru"), good="up"),
        card_html(int(latest["burned"]), "burned", delta=daily_delta("burned"), good="up"),
        card_html(
            f"{latest['progression']:.4f}%",
            "progression",
            delta=(latest["progression"] - week_ago["progression"]) if week_ago is not None else None,
            good="up",
            fmt="{:+.4f} pts",
        ),
        card_html(
            f"{acc7:.0f}%" if acc7 is not None else "—",
            f"first-try accuracy, 7d ({items7} reviews)",
            delta=(acc7 - acc14) if acc7 is not None and acc14 is not None else None,
            good="up",
            fmt="{:+.0f} pts",
        ),
        card_html(f"{streak} d", "streak", note=f"{last30} of the last 30 days active"),
    ]
    return "".join(cards), proj, rows


class Renderer:
    """Embeds plotly.js once, with the first chart, whatever the order."""

    def __init__(self, inline):
        self.js = True if inline else "cdn"

    def chart(self, fig):
        if fig is None:
            return ""
        html = fig.to_html(
            full_html=False,
            include_plotlyjs=self.js,
            default_width="100%",
            config={"displayModeBar": False, "responsive": True},
        )
        self.js = False
        return f'<div class="chart">{html}</div>'


CSS = f"""
    :root {{
        --bg: {BG}; --surface: {CARD_BG}; --line: {BORDER};
        --ink: #ffffff; --text: #b9b9c7; --muted: {MUTED};
        --good: {GOOD}; --bad: {BAD}; --warn: {WARN};
        --focus: {TYPE_COLORS["kanji"]};
        --radius: 8px; --gutter: 24px;
        color-scheme: dark;
    }}
    *, *::before, *::after {{ box-sizing: border-box; }}
    body {{
        background: var(--bg); color: var(--text);
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
            'Hiragino Sans', 'Noto Sans JP', sans-serif;
        font-variant-numeric: tabular-nums;
        margin: 0 auto; padding: var(--gutter); max-width: 1300px; line-height: 1.5;
    }}
    a {{ color: inherit; }}
    :focus-visible {{ outline: 2px solid var(--focus); outline-offset: 2px; border-radius: 2px; }}
    header {{ margin-bottom: 8px; }}
    h1 {{ color: var(--ink); font-size: 1.6rem; font-weight: 600; margin: 0 0 2px; }}
    h2 {{ color: var(--ink); font-size: 1.3rem; font-weight: 600; margin: 48px 0 2px; }}
    h3 {{ color: var(--ink); font-size: 1.05rem; font-weight: 600; margin: 32px 0 10px; }}
    .sub {{ color: var(--muted); font-size: 0.9rem; margin: 0; }}
    .section-sub {{ color: var(--muted); margin: 0 0 16px; font-size: 0.95rem; }}
    .cards {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(min(132px, 100%), 1fr)); gap: 12px; margin-bottom: 16px; }}
    .card {{ background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); padding: 12px 14px; min-width: 0; }}
    .card-value {{ font-size: 1.45rem; white-space: nowrap; color: var(--ink); font-weight: 600; line-height: 1.2; }}
    .card-label {{ font-size: 0.85rem; color: var(--text); margin-top: 4px; }}
    .card-delta {{ font-size: 0.8rem; color: var(--muted); margin-top: 2px; }}
    .grid2 {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(min(440px, 100%), 1fr)); gap: 16px; }}
    .chart {{ padding: 8px; border-radius: var(--radius); border: 1px solid var(--line); background: var(--surface); margin: 16px 0; min-width: 0; }}
    .grid2 .chart {{ margin: 0; }}
    .table-wrap {{ overflow-x: auto; border: 1px solid var(--line); border-radius: var(--radius); background: var(--surface); }}
    table {{ width: 100%; border-collapse: collapse; }}
    th, td {{ padding: 9px 14px; text-align: left; border-bottom: 1px solid var(--line); white-space: nowrap; }}
    tbody tr:last-child td {{ border-bottom: 0; }}
    th {{ color: var(--muted); font-size: 0.85rem; font-weight: 500; }}
    td.num, th.num {{ text-align: right; }}
    td.item {{ font-size: 1.35rem; }}
    td.item a {{ text-decoration: none; }}
    td.item a:hover {{ text-decoration: underline; }}
    footer {{ color: var(--muted); font-size: 0.85rem; margin-top: 48px; padding-top: 16px; border-top: 1px solid var(--line); }}
    footer p {{ margin: 0 0 4px; }}
    @media (max-width: 600px) {{
        :root {{ --gutter: 16px; }}
        h1 {{ font-size: 1.35rem; }}
        h2 {{ margin-top: 36px; }}
        .card-value {{ font-size: 1.25rem; }}
        .chart {{ padding: 4px; }}
    }}
    @media (prefers-reduced-motion: reduce) {{
        *, *::before, *::after {{ transition: none !important; animation: none !important; }}
    }}
"""


def build_dashboard(inline_plotly=False):
    now = now_local()
    df = get_dataframe()
    details = load_details(get_snapshots()[-1])
    metas, fulls, deltas = get_hourly_data()
    days = day_activity(metas, deltas)
    cards, proj, level_rows = build_cards(df, details, fulls, deltas, days, now)
    backlog = backlog_projection(fulls, now)

    r = Renderer(inline_plotly)
    latest_snapshot = max([m["time"] for m in metas], default=None)
    freshness = f"hourly snapshot {latest_snapshot:%b %d %H:%M}" if latest_snapshot else f"archive {df.iloc[-1]['date']}"

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <title>WaniKani Stats</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>{CSS}</style>
</head>
<body>
    <header>
        <h1>WaniKani Statistics</h1>
        <p class="sub">Updated from the {freshness} and the nightly archive of {df.iloc[-1]["date"]}. Times are {LOCAL_TZ.key}.</p>
    </header>

    <h2>Now</h2>
    <div class="section-sub">Where you stand today. Deltas compare with 7 days ago; green is progress.</div>
    <div class="cards">{cards}</div>
    <div class="grid2">
        {r.chart(fig_backlog(fulls, backlog, now))}
        {r.chart(fig_forecast(details))}
    </div>

    <h2>Habit</h2>
    <div class="section-sub">Consistency is what moves the backlog. From the hourly snapshots since 2026-09-10.</div>
    {r.chart(fig_calendar(days, now.date()))}
    {r.chart(fig_hourly_grid(metas, deltas, now.date()))}
    {r.chart(fig_profile(deltas, now.date()))}
    {r.chart(fig_sessions(deltas, now))}
    {r.chart(fig_srs_flow(deltas, now))}

    <h2>Progress</h2>
    <div class="section-sub">Level pace against the December targets, SRS health, and what keeps failing.</div>
    {r.chart(fig_level_path(level_rows, proj, now))}
    <div class="grid2">
        {r.chart(fig_level_days(level_rows, proj))}
        {r.chart(fig_stage_accuracy(deltas, now))}
    </div>
    {r.chart(fig_srs_composition(df, now))}
    <div class="grid2">
        {r.chart(fig_progression(df, now))}
        {r.chart(fig_leech_trend(df, now))}
    </div>
    {r.chart(fig_accuracy_hist(details))}
    {leech_table_html(details)}

    <script>window.addEventListener("load", () => window.dispatchEvent(new Event("resize")));</script>
    <footer>
        <p>Built from {len(df)} daily archives and {len(deltas)} recorded active hours. Read-only.</p>
        <p><a href="/download">Download a standalone copy</a></p>
    </footer>
</body>
</html>"""


def build_widget():
    """Compact read-only view for a Glance extension widget: cards only."""
    now = now_local()
    df = get_dataframe()
    details = load_details(get_snapshots()[-1])
    metas, fulls, deltas = get_hourly_data()
    days = day_activity(metas, deltas)
    cards, _, _ = build_cards(df, details, fulls, deltas, days, now)
    return f"""<style>{CSS} body {{ padding: 0; }} .cards {{ grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); margin: 0; }}</style>
<div class="cards">{cards}</div>"""


@app.route("/")
def index():
    return Response(build_dashboard(), content_type="text/html")


@app.route("/widget")
def widget():
    response = Response(build_widget(), content_type="text/html")
    response.headers["Widget-Content-Type"] = "html"
    response.headers["Widget-Title"] = "WaniKani"
    return response


@app.route("/download")
def download_dashboard():
    response = Response(build_dashboard(inline_plotly=True), content_type="text/html")
    response.headers["Content-Disposition"] = "attachment; filename=wanikani_dashboard.html"
    return response


@app.route("/health")
def health():
    return {"status": "ok", "service": "wanikani-stats"}


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "generate":
        output_file = sys.argv[2] if len(sys.argv) > 2 else "wanikani_dashboard.html"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(build_dashboard(inline_plotly=True))
        print(f"Standalone dashboard written to {output_file}")
    else:
        port = int(sys.argv[1]) if len(sys.argv) > 1 else 8501
        print(f"Starting WaniKani Stats on port {port}")
        app.run(host="0.0.0.0", port=port, debug=False)
