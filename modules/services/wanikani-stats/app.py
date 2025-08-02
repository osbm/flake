import zipfile
import json
from pathlib import Path
from flask import Flask, render_template_string, Response
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib
import functools

matplotlib.use('agg')
# set dark theme for plots
sns.set_theme(style="darkgrid")
plt.style.use('dark_background')

app = Flask(__name__)
DATA_DIR = Path("/var/lib/wanikani-logs")

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

        # with z.open("subjects.json") as f:
        #     subjects_data = json.load(f)
        #     print(f"Found total data subjects: {subjects_data['total_count']}")
        #     data["total_subjects"] = subjects_data['total_count']
        # so the subjects.json file is about 50 mb so we are just not gonna care if this value changes (doesnt change much)
        data["total_subjects"] = 9300

        with z.open("assignments.json") as f:
            assignments_data = json.load(f)
            print(f"Found total assignments: {assignments_data['total_count']}")
            data["total_assignments"] = assignments_data['total_count']

            # now the data key will give us all the srs stages
            srs_stages = [0 for _ in range(10)]  # 10 SRS stages
            for assignment in assignments_data['data']:
                srs_stage = assignment['data']['srs_stage']
                srs_stages[srs_stage] += 1

            # add srs stages to data
            for i, count in enumerate(srs_stages):
                data[f'srs_stage_{i}'] = count

    print(data)
    return data

def get_dataframe(list_of_daily_data):
    """Convert a list of daily data dictionaries into a pandas DataFrame."""
    df = pd.DataFrame(list_of_daily_data)

    df["progression"] = df.apply(lambda row: sum(row[f'srs_stage_{i}'] * (i + 1) for i in range(10)) / (row['total_subjects'] * 10) * 100, axis=1)

    df["apprentice"] = df.apply(lambda row: row['srs_stage_1'] + row['srs_stage_2'] + row['srs_stage_3'] + row['srs_stage_4'], axis=1)
    df["guru"] = df.apply(lambda row: row['srs_stage_5'] + row['srs_stage_6'], axis=1)
    df["master"] = df['srs_stage_7']
    df["enlightened"] = df["srs_stage_8"]
    df["burned"] = df["srs_stage_9"]

    return df

def get_svg_plot(df, column, title, ylabel):
    """Generate an SVG plot for a given DataFrame column."""
    plt.figure(figsize=(10, 6), facecolor='#151519')
    plt.plot(df['date'], df[column], marker='o', label=column.capitalize())
    plt.title(title)
    plt.xlabel('Date')
    plt.ylabel(ylabel)
    # Show every 10th date label
    plt.xticks(range(0, len(df['date']), 10), df['date'][::10], rotation=45)
    plt.grid()
    plt.legend()
    plt.gca().set_facecolor('#151519')
    plt.tight_layout()

    # Save to string buffer
    import io
    buffer = io.StringIO()
    plt.savefig(buffer, format='svg', bbox_inches='tight')
    svg_content = buffer.getvalue()
    buffer.close()
    plt.close()

    return svg_content

def render_html(df):
    """Render the DataFrame as HTML."""
    reviews_svg = get_svg_plot(df, 'num_reviews', 'Daily Reviews', 'Number of Reviews')
    lessons_svg = get_svg_plot(df, 'num_lessons', 'Daily Lessons', 'Number of Lessons')
    progression_svg = get_svg_plot(df, 'progression', 'SRS Progression', 'Progression (%)')

    # srs stages
    srs_stage_apprentice_svg = get_svg_plot(df, 'apprentice', 'Apprentice Stage', 'Number of Subjects')
    srs_stage_guru_svg = get_svg_plot(df, 'guru', 'Guru Stage', 'Number of Subjects')
    srs_stage_master_svg = get_svg_plot(df, 'master', 'Master Stage', 'Number of Subjects')
    srs_stage_enlightened_svg = get_svg_plot(df, 'enlightened', 'Enlightened Stage', 'Number of Subjects')
    srs_stage_burned_svg = get_svg_plot(df, 'burned', 'Burned Stage', 'Number of Subjects')

    # Render HTML with embedded SVGs
    html_content = f"""
    <html>
        <head>
            <title>WaniKani Stats</title>
            <style>
                body {{
                    background-color: #151519;
                    color: #8b8b9c;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    margin: 0;
                    padding: 20px;
                }}
                svg {{
                    display: block;
                    margin: 17px auto;
                    background-color: transparent;
                    border-radius: 5px;
                    overflow: hidden;
                    border: 1px solid #1e1e24;
                }}
            </style>
        </head>
        <body>
            {reviews_svg}
            {lessons_svg}
            {progression_svg}
            {srs_stage_apprentice_svg}
            {srs_stage_guru_svg}
            {srs_stage_master_svg}
            {srs_stage_enlightened_svg}
            {srs_stage_burned_svg}
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

    response = Response(render_html(df), content_type='text/html')
    response.headers['Widget-Content-Type'] = 'html'
    response.headers['Widget-Title'] = 'WaniKani Statistics'
    return response

@app.route('/health')
def health():
    """Health check endpoint"""
    return {'status': 'ok', 'service': 'wanikani-stats'}

if __name__ == '__main__':
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8501
    print(f"Starting WaniKani Stats Flask app on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)

