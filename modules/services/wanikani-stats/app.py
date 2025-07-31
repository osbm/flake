import zipfile
import json
from pathlib import Path
from flask import Flask, render_template_string, Response
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib
import functools

matplotlib.use('agg')
sns.set_theme(style="whitegrid")
app = Flask(__name__)
DATA_DIR = Path("./data")

def get_zip_file_names():
    """Get a list of zip files in the data directory."""
    return [f for f in DATA_DIR.glob("*.zip") if f.is_file()]


# this is an expensive function so we will cache the results
@functools.lru_cache(maxsize=None)
def load_zip(zip_path):
    print(f"Processing {zip_path}")
    """Load a zip file and return its contents as a dictionary."""
    with zipfile.ZipFile(zip_path, 'r') as z:
        data = {}
        # just read summary.json
        with z.open("summary.json") as f:
            summary_data = json.load(f)
            num_reviews = len(summary_data['data']['reviews'][0]["subject_ids"])
            num_lessons = len(summary_data['data']['lessons'][0]["subject_ids"])
            data["num_reviews"] = num_reviews
            data["num_lessons"] = num_lessons
            # wanikani_data_2025-05-18.zip
            data["date"] = zip_path.stem.split('_')[-1].replace('.zip', '')
    return data

def get_dataframe(list_of_daily_data):
    """Convert a list of daily data dictionaries into a pandas DataFrame."""
    df = pd.DataFrame(list_of_daily_data)
    return df

def render_html(df):
    """Render the DataFrame as HTML."""
    import io

    # Generate reviews plot SVG
    plt.figure(figsize=(10, 5))
    plt.plot(df['date'], df['num_reviews'], marker='o', label='Reviews')
    plt.title('Daily Reviews')
    plt.xlabel('Date')
    plt.ylabel('Number of Reviews')
    # Show every 10th date label
    plt.xticks(range(0, len(df['date']), 10), df['date'][::10], rotation=45)
    plt.grid()
    plt.legend()

    # Save to string buffer
    reviews_buffer = io.StringIO()
    plt.savefig(reviews_buffer, format='svg')
    reviews_svg = reviews_buffer.getvalue()
    reviews_buffer.close()
    plt.close()

    # Generate lessons plot SVG
    plt.figure(figsize=(10, 5))
    plt.plot(df['date'], df['num_lessons'], marker='o', label='Lessons', color='orange')
    plt.title('Daily Lessons')
    plt.xlabel('Date')
    plt.ylabel('Number of Lessons')
    # Show every 10th date label
    plt.xticks(range(0, len(df['date']), 10), df['date'][::10], rotation=45)
    plt.grid()
    plt.legend()

    # Save to string buffer
    lessons_buffer = io.StringIO()
    plt.savefig(lessons_buffer, format='svg')
    lessons_svg = lessons_buffer.getvalue()
    lessons_buffer.close()
    plt.close()

    # Render HTML with embedded SVGs
    html_content = f"""
    <html>
        <head><title>WaniKani Stats</title></head>
        <body>
            <h1>WaniKani Daily Stats</h1>
            <h2>Reviews</h2>
            {reviews_svg}
            <h2>Lessons</h2>
            {lessons_svg}
        </body>
    </html>
    """
    return render_template_string(html_content)

@app.route('/')
def index():
    """Index route"""
    file_names = get_zip_file_names()

    print(f"Found {len(file_names)} zip files in {DATA_DIR}")
    list_of_daily_data = []
    for file_name in file_names:
        daily_data = load_zip(file_name)
        list_of_daily_data.append(daily_data)

    df = get_dataframe(list_of_daily_data)
    # sort by date string
    df.sort_values(by='date', inplace=True)

    return render_html(df)

@app.route('/health')
def health():
    """Health check endpoint"""
    return {'status': 'ok', 'service': 'wanikani-stats'}

if __name__ == '__main__':
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8501
    print(f"Starting WaniKani Stats Flask app on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)

