import zipfile
import json
from pathlib import Path
import streamlit as st
import pandas as pd

DATA_DIR = Path("/var/lib/wanikani-logs")
print("starting the WaniKani service")
def load_data():
    # records = []
    for zip_path in sorted(DATA_DIR.glob("wanikani_data_*.zip")):
        st.write(f"Processing {zip_path.name}...")
        with zipfile.ZipFile(zip_path) as z:
            for name in z.namelist():
                print(f"Processing file: {name}")
                # with z.open(name) as f:
                #     data = json.load(f)
                #     date = zip_path.stem.split("_")[-1]
                #     # Adapt below to match your JSON structure
                #     record = {
                #         "date": date,
                #         "available_lessons": data.get("lessons", {}).get("available", 0),
                #         "level": data.get("level", 0),
                #     }
                #     records.append(record)
    # return pd.DataFrame(records)

st.title("📈 WaniKani Progress Tracker")
# df = load_data()
# st.line_chart(df.set_index("date"))
