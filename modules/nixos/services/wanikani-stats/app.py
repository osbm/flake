"""WaniKani statistics dashboard.

Reads the daily archive zips produced by wanikani-fetch-data plus the
standalone subjects.json and serves an interactive plotly dashboard.
"""

import functools
import json
import os
import sys
import zipfile
from datetime import datetime
from pathlib import Path

import pandas as pd
import plotly.graph_objects as go
import plotly.io as pio
from flask import Flask, Response

pio.templates.default = "plotly_dark"

app = Flask(__name__)
DATA_DIR = Path(os.environ.get("WANIKANI_LOG_DIR", "/var/lib/wanikani-logs"))

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
APPRENTICE_SHADES = ["#ff8ac2", "#f45cab", "#dd0093", "#a80070"]
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

BG = "#151519"
CARD_BG = "#1a1a1f"
BORDER = "#26262e"

PLOT_LAYOUT = dict(
    template="plotly_dark",
    plot_bgcolor=CARD_BG,
    paper_bgcolor=CARD_BG,
    height=420,
    margin=dict(l=50, r=30, t=60, b=50),
    legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
)


def get_zip_files():
    return sorted(f for f in DATA_DIR.glob("wanikani_data_*.zip") if f.is_file())


def read_json_from_zip(zip_path, name):
    with zipfile.ZipFile(zip_path, "r") as z:
        if name not in z.namelist():
            return None
        with z.open(name) as f:
            return json.load(f)


@functools.lru_cache(maxsize=None)
def load_zip_timeseries(zip_path):
    """Per-day numbers used by the time-series charts (cached per zip)."""
    data = {"date": zip_path.stem.split("_")[-1]}

    summary = read_json_from_zip(zip_path, "summary.json")
    data["num_reviews"] = len(summary["data"]["reviews"][0]["subject_ids"])
    data["num_lessons"] = len(summary["data"]["lessons"][0]["subject_ids"])

    assignments = read_json_from_zip(zip_path, "assignments.json")
    srs_stages = [0] * 10
    for assignment in assignments["data"]:
        srs_stages[assignment["data"]["srs_stage"]] += 1
    for i, count in enumerate(srs_stages):
        data[f"srs_stage_{i}"] = count

    return data


@functools.lru_cache(maxsize=4)
def load_details(zip_path):
    """Detail data (only needed from the newest zip)."""
    return {
        "user": read_json_from_zip(zip_path, "user.json"),
        "summary": read_json_from_zip(zip_path, "summary.json"),
        "level_progressions": read_json_from_zip(zip_path, "level_progressions.json"),
        "review_statistics": read_json_from_zip(zip_path, "review_statistics.json"),
        "assignments": read_json_from_zip(zip_path, "assignments.json"),
    }


@functools.lru_cache(maxsize=2)
def load_subjects(cache_key):
    """subject_id -> {characters, level, type}. cache_key busts on file change.

    Prefers the standalone subjects.json; falls back to the newest zip that
    still contains one (pre-refactor archives).
    """
    standalone = DATA_DIR / "subjects.json"
    subjects = None
    if standalone.is_file():
        with open(standalone) as f:
            subjects = json.load(f)
    else:
        for zip_path in reversed(get_zip_files()):
            subjects = read_json_from_zip(zip_path, "subjects.json")
            if subjects is not None:
                break

    if subjects is None:
        return {}, 0

    id_map = {}
    active = 0
    for subj in subjects["data"]:
        hidden = subj["data"].get("hidden_at")
        if not hidden:
            active += 1
        id_map[subj["id"]] = {
            "characters": subj["data"].get("characters") or subj["data"].get("slug"),
            "level": subj["data"]["level"],
            "type": subj["object"],
            "hidden": bool(hidden),
        }
    return id_map, active


def subjects_cache_key():
    standalone = DATA_DIR / "subjects.json"
    if standalone.is_file():
        return f"standalone:{standalone.stat().st_mtime_ns}"
    files = get_zip_files()
    return f"zip:{files[-1].name}" if files else "none"


def parse_ts(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00")) if value else None


def get_dataframe():
    df = pd.DataFrame(load_zip_timeseries(p) for p in get_zip_files())
    df.sort_values(by="date", inplace=True)

    _, total_subjects = load_subjects(subjects_cache_key())
    if not total_subjects:
        total_subjects = 9300  # last resort if no subjects source exists

    df["progression"] = df.apply(
        lambda row: sum(row[f"srs_stage_{i}"] * (i + 1) for i in range(10))
        / (total_subjects * 10)
        * 100,
        axis=1,
    )
    df["apprentice"] = sum(df[f"srs_stage_{i}"] for i in range(1, 5))
    df["guru"] = df["srs_stage_5"] + df["srs_stage_6"]
    df["master"] = df["srs_stage_7"]
    df["enlightened"] = df["srs_stage_8"]
    df["burned"] = df["srs_stage_9"]
    return df


def fig_srs_composition(df):
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
                x=df["date"],
                y=df[column],
                mode="lines",
                name=name,
                stackgroup="one",
                line=dict(width=0.5, color=STAGE_COLORS[name]),
            )
        )
    fig.update_layout(
        title="SRS Stage Composition Over Time",
        yaxis_title="Items",
        **PLOT_LAYOUT,
    )
    fig.update_xaxes(type="date")
    return fig


def fig_daily_activity(df):
    fig = go.Figure()
    fig.add_trace(
        go.Scatter(
            x=df["date"],
            y=df["num_reviews"],
            mode="lines+markers",
            name="Reviews in queue",
            line=dict(width=2, color="#00AAFF"),
            marker=dict(size=5),
        )
    )
    fig.add_trace(
        go.Scatter(
            x=df["date"],
            y=df["num_lessons"],
            mode="lines+markers",
            name="Lessons available",
            line=dict(width=2, color="#FF00AA"),
            marker=dict(size=5),
        )
    )
    fig.update_layout(
        title="Daily Queue at Snapshot Time (02:00)",
        yaxis_title="Items",
        **PLOT_LAYOUT,
    )
    fig.update_xaxes(type="date")
    return fig


def fig_progression(df):
    fig = go.Figure()
    fig.add_trace(
        go.Scatter(
            x=df["date"],
            y=df["progression"],
            mode="lines",
            name="Progression",
            line=dict(width=2.5, color="#faaa1e"),
            fill="tozeroy",
            fillcolor="rgba(250, 170, 30, 0.15)",
        )
    )
    fig.update_layout(
        title="Overall SRS Progression",
        yaxis_title="Progression (%)",
        **PLOT_LAYOUT,
    )
    fig.update_xaxes(type="date")
    return fig


def fig_apprentice_breakdown(df):
    fig = go.Figure()
    for i in range(1, 5):
        fig.add_trace(
            go.Scatter(
                x=df["date"],
                y=df[f"srs_stage_{i}"],
                mode="lines",
                name=f"Apprentice {'I' * i if i < 4 else 'IV'}",
                stackgroup="one",
                line=dict(width=0.5, color=APPRENTICE_SHADES[i - 1]),
            )
        )
    fig.update_layout(
        title="Apprentice Stage Breakdown",
        yaxis_title="Items",
        **PLOT_LAYOUT,
    )
    fig.update_xaxes(type="date")
    return fig


def fig_level_speed(details):
    now = datetime.now().astimezone()
    rows = []
    for lp in details["level_progressions"]["data"]:
        d = lp["data"]
        unlocked = parse_ts(d.get("unlocked_at"))
        passed = parse_ts(d.get("passed_at"))
        if unlocked is None or d.get("abandoned_at"):
            continue
        end = passed or now
        rows.append(
            {
                "level": d["level"],
                "days": (end - unlocked).total_seconds() / 86400,
                "in_progress": passed is None,
            }
        )
    if not rows:
        return None

    fig = go.Figure()
    fig.add_trace(
        go.Bar(
            x=[r["level"] for r in rows],
            y=[r["days"] for r in rows],
            marker_color=[
                "#4a4a55" if r["in_progress"] else "#882D9E" for r in rows
            ],
        )
    )
    fig.update_layout(
        title="Days per Level (grey = current, still in progress)",
        xaxis_title="Level",
        yaxis_title="Days",
        **PLOT_LAYOUT,
    )
    return fig


def fig_accuracy(details):
    stats = details["review_statistics"]["data"]
    fig = go.Figure()
    for subject_type in ["radical", "kanji", "vocabulary"]:
        values = [
            s["data"]["percentage_correct"]
            for s in stats
            if s["data"]["subject_type"].startswith(subject_type)
            and not s["data"].get("hidden")
        ]
        if not values:
            continue
        fig.add_trace(
            go.Histogram(
                x=values,
                name=subject_type,
                xbins=dict(start=0, end=101, size=5),
                marker_color=TYPE_COLORS[subject_type],
                opacity=0.85,
            )
        )
    fig.update_layout(
        title="Review Accuracy Distribution",
        xaxis_title="Percentage correct",
        yaxis_title="Items",
        barmode="stack",
        **PLOT_LAYOUT,
    )
    return fig


def fig_forecast(details):
    buckets = details["summary"]["data"]["reviews"][1:]
    if not buckets:
        return None
    fig = go.Figure()
    fig.add_trace(
        go.Bar(
            x=[parse_ts(b["available_at"]).strftime("%H:%M") for b in buckets],
            y=[len(b["subject_ids"]) for b in buckets],
            marker_color="#00AAFF",
        )
    )
    fig.update_layout(
        title="Review Forecast, 24h From Snapshot",
        xaxis_title="Hour",
        yaxis_title="Reviews unlocking",
        **PLOT_LAYOUT,
    )
    return fig


def leech_table_html(details):
    id_map, _ = load_subjects(subjects_cache_key())
    if not id_map:
        return "<p>subjects.json not available yet — leech table needs it.</p>"

    srs_by_subject = {
        a["data"]["subject_id"]: a["data"]["srs_stage"]
        for a in details["assignments"]["data"]
    }

    leeches = []
    for s in details["review_statistics"]["data"]:
        d = s["data"]
        wrong = d["meaning_incorrect"] + d["reading_incorrect"]
        stage = srs_by_subject.get(d["subject_id"], 0)
        if wrong < 2 or d.get("hidden") or stage == 9:
            continue
        subj = id_map.get(d["subject_id"])
        if subj is None:
            continue
        leeches.append(
            {
                "characters": subj["characters"],
                "type": d["subject_type"],
                "level": subj["level"],
                "stage": SRS_STAGE_NAMES[stage],
                "accuracy": d["percentage_correct"],
                "wrong": wrong,
            }
        )

    leeches.sort(key=lambda x: (x["accuracy"], -x["wrong"]))
    rows = "".join(
        f"""<tr>
            <td class="item" style="color: {TYPE_COLORS.get(l["type"], "#fff")}">{l["characters"]}</td>
            <td>{l["type"].replace("_", " ")}</td>
            <td>{l["level"]}</td>
            <td>{l["stage"]}</td>
            <td>{l["accuracy"]}%</td>
            <td>{l["wrong"]}</td>
        </tr>"""
        for l in leeches[:20]
    )
    return f"""
    <h2>Leeches — your 20 most-missed items</h2>
    <table>
        <thead><tr>
            <th>Item</th><th>Type</th><th>Level</th><th>SRS stage</th>
            <th>Accuracy</th><th>Times wrong</th>
        </tr></thead>
        <tbody>{rows}</tbody>
    </table>
    """


def summary_cards_html(df, details):
    user = details["user"]["data"]
    stats = details["review_statistics"]["data"]
    correct = sum(
        s["data"]["meaning_correct"] + s["data"]["reading_correct"] for s in stats
    )
    incorrect = sum(
        s["data"]["meaning_incorrect"] + s["data"]["reading_incorrect"] for s in stats
    )
    accuracy = 100 * correct / (correct + incorrect) if correct + incorrect else 0
    latest = df.iloc[-1]

    cards = [
        (f"Level {user['level']}", user["username"]),
        (f"{len(df)}", "days tracked"),
        (f"{int(latest['burned'])}", "burned"),
        (f"{int(latest['apprentice'])}", "apprentice"),
        (f"{int(latest['guru'])}", "guru"),
        (f"{accuracy:.1f}%", "review accuracy"),
    ]
    return "".join(
        f'<div class="card"><div class="card-value">{value}</div>'
        f'<div class="card-label">{label}</div></div>'
        for value, label in cards
    )


def build_dashboard(inline_plotly=False):
    df = get_dataframe()
    details = load_details(get_zip_files()[-1])

    figures = [
        fig_srs_composition(df),
        fig_progression(df),
        fig_daily_activity(df),
        fig_apprentice_breakdown(df),
        fig_level_speed(details),
        fig_accuracy(details),
        fig_forecast(details),
    ]

    chart_html = []
    plotly_js = True if inline_plotly else "cdn"
    for fig in figures:
        if fig is None:
            continue
        chart_html.append(
            fig.to_html(
                full_html=False,
                include_plotlyjs=plotly_js,  # only the first embed carries plotly.js
                default_width="100%",
                config={"displayModeBar": False, "responsive": True},
            )
        )
        plotly_js = False

    charts = "".join(
        f'<div class="chart-container">{c}</div>' for c in chart_html
    )
    snapshot_date = df.iloc[-1]["date"]

    return f"""<!DOCTYPE html>
<html>
<head>
    <title>WaniKani Stats</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {{
            background-color: {BG};
            color: #b9b9c7;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
                'Hiragino Sans', 'Noto Sans JP', sans-serif;
            margin: 0 auto;
            padding: 24px;
            max-width: 1300px;
            line-height: 1.6;
        }}
        h1 {{ text-align: center; color: #fff; font-weight: 300; margin-bottom: 4px; }}
        h2 {{ color: #fff; font-weight: 400; margin-top: 36px; }}
        .dashboard-info {{ text-align: center; color: #77778a; margin-bottom: 28px; }}
        .cards {{ display: flex; flex-wrap: wrap; gap: 14px; justify-content: center; margin-bottom: 28px; }}
        .card {{
            background: {CARD_BG}; border: 1px solid {BORDER}; border-radius: 10px;
            padding: 16px 26px; text-align: center; min-width: 110px;
        }}
        .card-value {{ font-size: 1.7em; color: #fff; font-weight: 600; }}
        .card-label {{ font-size: 0.8em; color: #77778a; text-transform: uppercase; letter-spacing: 0.05em; }}
        .chart-container {{
            margin: 18px 0; padding: 12px; border-radius: 10px;
            border: 1px solid {BORDER}; background-color: {CARD_BG};
        }}
        table {{ width: 100%; border-collapse: collapse; background: {CARD_BG};
                 border: 1px solid {BORDER}; border-radius: 10px; overflow: hidden; }}
        th, td {{ padding: 9px 14px; text-align: left; border-bottom: 1px solid {BORDER}; }}
        th {{ color: #77778a; text-transform: uppercase; font-size: 0.75em; letter-spacing: 0.05em; }}
        td.item {{ font-size: 1.35em; }}
    </style>
</head>
<body>
    <h1>WaniKani Statistics</h1>
    <div class="dashboard-info">snapshot {snapshot_date} · updates daily at 02:00</div>
    <div class="cards">{summary_cards_html(df, details)}</div>
    {charts}
    {leech_table_html(details)}
</body>
</html>"""


@app.route("/")
def index():
    response = Response(build_dashboard(), content_type="text/html")
    response.headers["Widget-Content-Type"] = "html"
    response.headers["Widget-Title"] = "WaniKani Statistics"
    return response


@app.route("/download")
def download_dashboard():
    response = Response(build_dashboard(inline_plotly=True), content_type="text/html")
    response.headers["Content-Disposition"] = (
        "attachment; filename=wanikani_dashboard.html"
    )
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
