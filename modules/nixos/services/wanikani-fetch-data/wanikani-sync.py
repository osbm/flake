"""Unified WaniKani puller, run hourly by a single timer.

Every run writes an hourly activity snapshot (assignments +
review_statistics + summary) as a self-contained file — a lost hour
loses only that hour. Dead hours (no data change) write a tiny stub.
The first run of a local day additionally archives the full daily
dump (all topics) exactly like the old 02:00 job.

Output layout is unchanged from the old two-script setup:
  wanikani_data_YYYY-MM-DD/   daily archive
  subjects.json               single current copy (edited daily by WK)
  subjects-changes/           dated level-map snapshots on real change
  hourly/YYYY-MM-DD/HH.json   hourly snapshots (UTC)
"""
import json
import os
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

BASE = Path("/var/lib/wanikani-logs")
API = "https://api.wanikani.com/v2"
TOKEN = os.environ["WANIKANI_API_TOKEN"]

DAILY_TOPICS = [
    "assignments",
    "level_progressions",
    "resets",
    "reviews",
    "review_statistics",
    "spaced_repetition_systems",
    "study_materials",
    "subjects",
]


def get(url):
    req = urllib.request.Request(url, headers={
        "Wanikani-Revision": "20170710",
        "Authorization": f"Bearer {TOKEN}",
    })
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def fetch_all(topic):
    page = get(f"{API}/{topic}")
    merged = {
        "object": page["object"],
        "total_count": page["total_count"],
        "data_updated_at": page["data_updated_at"],
        "data": list(page["data"]),
    }
    while page["pages"].get("next_url"):
        page = get(page["pages"]["next_url"])
        merged["data"].extend(page["data"])
    return merged


def write_json(path, obj):
    # atomic: a failed run must not leave a 0-byte file behind
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(obj, separators=(",", ":")))
    tmp.replace(path)


def hibernating():
    try:
        get(f"{API}/user")
        return False
    except urllib.error.HTTPError as e:
        if "hibernating" in e.read().decode(errors="replace"):
            return True
        raise


def level_map(subjects):
    rows = [
        {"id": s["id"], "level": s["data"]["level"],
         "hidden": s["data"].get("hidden_at") is not None}
        for s in subjects["data"]
    ]
    return sorted(rows, key=lambda r: r["id"])


def daily():
    """Full archive, once per local day. Returns fetched topics for reuse."""
    day = datetime.now().strftime("%Y-%m-%d")
    out_dir = BASE / f"wanikani_data_{day}"
    if out_dir.exists() or out_dir.with_suffix(".zip").exists():
        return {}

    fetched = {t: fetch_all(t) for t in DAILY_TOPICS}

    # subjects.json is large and WK edits its content almost daily, so it
    # stays a single current copy; archive only the level map, and only
    # when levels/membership actually changed
    subjects = fetched.pop("subjects")
    proj_new = level_map(subjects)
    current = BASE / "subjects.json"
    proj_old = None
    if current.exists():
        proj_old = level_map(json.loads(current.read_text()))
    if proj_new != proj_old:
        changes = BASE / "subjects-changes"
        changes.mkdir(parents=True, exist_ok=True)
        write_json(changes / f"levels_{day}.json", proj_new)
        print(f"subject levels changed, archived levels_{day}.json")
    write_json(current, subjects)

    tmp_dir = BASE / f".wanikani_data_{day}.tmp"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    for topic, payload in fetched.items():
        write_json(tmp_dir / f"{topic}.json", payload)
    write_json(tmp_dir / "summary.json", get(f"{API}/summary"))
    write_json(tmp_dir / "user.json", get(f"{API}/user"))
    tmp_dir.chmod(0o755)
    tmp_dir.rename(out_dir)
    print(f"daily archive written: {out_dir}")
    return fetched


def latest_snapshot(hourly_dir, skip):
    files = sorted(hourly_dir.glob("*/*.json"))
    for path in reversed(files):
        if path == skip:
            continue
        try:
            return json.loads(path.read_text())
        except (json.JSONDecodeError, OSError):
            continue  # 0-byte / corrupt leftovers from failed runs
    return None


def hourly(fetched):
    now = datetime.now(timezone.utc)
    out_dir = BASE / "hourly" / now.strftime("%Y-%m-%d")
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{now:%H}.json"

    def stamp(topic):
        page = get(f"{API}/{topic}?page_after_id=99999999")
        return page.get("data_updated_at")

    stamps = {t: stamp(t) for t in ("assignments", "review_statistics")}

    prev = latest_snapshot(BASE / "hourly", skip=out)
    if prev and prev.get("stamps") == stamps:
        write_json(out, {
            "fetched_at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "unchanged": True, "stamps": stamps,
        })
        print("no activity — stub written")
        return

    summary = get(f"{API}/summary")
    write_json(out, {
        "fetched_at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "unchanged": False,
        "stamps": stamps,
        "summary": {
            "reviews_pending":
                len(summary["data"]["reviews"][0]["subject_ids"]),
            "lessons_pending":
                len(summary["data"]["lessons"][0]["subject_ids"]),
        },
        "assignments":
            fetched.get("assignments") or fetch_all("assignments"),
        "review_statistics":
            fetched.get("review_statistics") or fetch_all("review_statistics"),
    })
    print(f"full snapshot {out} ({out.stat().st_size} bytes)")


def main():
    if hibernating():
        print("account hibernating — skipping")
        return
    BASE.mkdir(parents=True, exist_ok=True)
    fetched = daily()
    hourly(fetched)


if __name__ == "__main__":
    main()
