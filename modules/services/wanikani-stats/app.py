import zipfile
import json
from pathlib import Path
from flask import Flask, render_template_string, Response
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
import plotly.io as pio
import functools

# Set Plotly dark theme
pio.templates.default = "plotly_dark"

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
    with zipfile.ZipFile(zip_path, "r") as z:
        data = {}
        # just read summary.json
        with z.open("summary.json") as f:
            summary_data = json.load(f)
            num_reviews = len(summary_data["data"]["reviews"][0]["subject_ids"])
            num_lessons = len(summary_data["data"]["lessons"][0]["subject_ids"])
            data["num_reviews"] = num_reviews
            data["num_lessons"] = num_lessons
            # wanikani_data_2025-05-18.zip
            data["date"] = zip_path.stem.split("_")[-1].replace(".zip", "")

        # with z.open("subjects.json") as f:
        #     subjects_data = json.load(f)
        #     print(f"Found total data subjects: {subjects_data['total_count']}")
        #     data["total_subjects"] = subjects_data['total_count']
        # so the subjects.json file is about 50 mb so we are just not gonna care if this value changes (doesnt change much)
        data["total_subjects"] = 9300

        with z.open("assignments.json") as f:
            assignments_data = json.load(f)
            print(f"Found total assignments: {assignments_data['total_count']}")
            data["total_assignments"] = assignments_data["total_count"]

            # now the data key will give us all the srs stages
            srs_stages = [0 for _ in range(10)]  # 10 SRS stages
            for assignment in assignments_data["data"]:
                srs_stage = assignment["data"]["srs_stage"]
                srs_stages[srs_stage] += 1

            # add srs stages to data
            for i, count in enumerate(srs_stages):
                data[f"srs_stage_{i}"] = count

    print(data)
    return data


def get_dataframe(list_of_daily_data):
    """Convert a list of daily data dictionaries into a pandas DataFrame."""
    df = pd.DataFrame(list_of_daily_data)

    df["progression"] = df.apply(
        lambda row: sum(row[f"srs_stage_{i}"] * (i + 1) for i in range(10))
        / (row["total_subjects"] * 10)
        * 100,
        axis=1,
    )

    df["apprentice"] = df.apply(
        lambda row: row["srs_stage_1"]
        + row["srs_stage_2"]
        + row["srs_stage_3"]
        + row["srs_stage_4"],
        axis=1,
    )

    # Individual apprentice stages for distribution analysis
    df["apprentice_1"] = df["srs_stage_1"]
    df["apprentice_2"] = df["srs_stage_2"]
    df["apprentice_3"] = df["srs_stage_3"]
    df["apprentice_4"] = df["srs_stage_4"]
    df["unlocked"] = df["srs_stage_0"]

    df["guru"] = df.apply(lambda row: row["srs_stage_5"] + row["srs_stage_6"], axis=1)
    df["master"] = df["srs_stage_7"]
    df["enlightened"] = df["srs_stage_8"]
    df["burned"] = df["srs_stage_9"]

    return df


def get_plotly_html(df, column, title, ylabel):
    """Generate an interactive Plotly HTML for a given DataFrame column."""
    fig = go.Figure()

    fig.add_trace(go.Scatter(
        x=df["date"],
        y=df[column],
        mode='lines+markers',
        name=column.capitalize(),
        line=dict(width=2),
        marker=dict(size=6)
    ))

    fig.update_layout(
        title=title,
        xaxis_title="Date",
        yaxis_title=ylabel,
        template="plotly_dark",
        plot_bgcolor='#151519',
        paper_bgcolor='#151519',
        width=1200,
        height=600,
        margin=dict(l=50, r=50, t=50, b=50)
    )

    # Show every 10th date label for better readability
    date_indices = list(range(0, len(df), 10))
    fig.update_xaxes(
        tickmode='array',
        tickvals=[df.iloc[i]["date"] for i in date_indices],
        ticktext=[df.iloc[i]["date"] for i in date_indices],
        tickangle=45
    )

    return fig.to_html(include_plotlyjs=True, div_id=f"plot_{column}")


def get_apprentice_distribution_html(df):
    """Generate a stacked area chart showing apprentice stage distribution over time."""
    fig = go.Figure()

    # Add stacked area traces
    fig.add_trace(go.Scatter(
        x=df["date"],
        y=df["apprentice_1"],
        mode='lines',
        name='Apprentice I',
        stackgroup='one',
        fillcolor='rgba(255, 107, 107, 0.8)',
        line=dict(width=0.5, color='#ff6b6b')
    ))

    fig.add_trace(go.Scatter(
        x=df["date"],
        y=df["apprentice_2"],
        mode='lines',
        name='Apprentice II',
        stackgroup='one',
        fillcolor='rgba(78, 205, 196, 0.8)',
        line=dict(width=0.5, color='#4ecdc4')
    ))

    fig.add_trace(go.Scatter(
        x=df["date"],
        y=df["apprentice_3"],
        mode='lines',
        name='Apprentice III',
        stackgroup='one',
        fillcolor='rgba(69, 183, 209, 0.8)',
        line=dict(width=0.5, color='#45b7d1')
    ))

    fig.add_trace(go.Scatter(
        x=df["date"],
        y=df["apprentice_4"],
        mode='lines',
        name='Apprentice IV',
        stackgroup='one',
        fillcolor='rgba(150, 206, 180, 0.8)',
        line=dict(width=0.5, color='#96ceb4')
    ))

    fig.update_layout(
        title="Apprentice Stage Distribution Over Time",
        xaxis_title="Date",
        yaxis_title="Number of Items",
        template="plotly_dark",
        plot_bgcolor='#151519',
        paper_bgcolor='#151519',
        width=1200,
        height=600,
        margin=dict(l=50, r=50, t=50, b=50),
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="right",
            x=1
        )
    )

    # Show every 10th date label for better readability
    date_indices = list(range(0, len(df), 10))
    fig.update_xaxes(
        tickmode='array',
        tickvals=[df.iloc[i]["date"] for i in date_indices],
        ticktext=[df.iloc[i]["date"] for i in date_indices],
        tickangle=45
    )

    return fig.to_html(include_plotlyjs=True, div_id="apprentice_distribution")


def generate_standalone_html(df, output_path=None):
    """Generate a completely self-contained HTML file with all charts."""
    # Generate all chart HTML
    reviews_html = get_plotly_html(df, "num_reviews", "Daily Reviews", "Number of Reviews")
    lessons_html = get_plotly_html(df, "num_lessons", "Daily Lessons", "Number of Lessons")
    progression_html = get_plotly_html(
        df, "progression", "SRS Progression", "Progression (%)"
    )
    apprentice_distribution_html = get_apprentice_distribution_html(df)
    srs_stage_apprentice_html = get_plotly_html(
        df, "apprentice", "Apprentice Stage", "Number of Subjects"
    )
    srs_stage_guru_html = get_plotly_html(df, "guru", "Guru Stage", "Number of Subjects")
    srs_stage_master_html = get_plotly_html(
        df, "master", "Master Stage", "Number of Subjects"
    )
    srs_stage_enlightened_html = get_plotly_html(
        df, "enlightened", "Enlightened Stage", "Number of Subjects"
    )
    srs_stage_burned_html = get_plotly_html(
        df, "burned", "Burned Stage", "Number of Subjects"
    )

    # Create complete standalone HTML
    html_content = f"""
    <!DOCTYPE html>
    <html>
        <head>
            <title>WaniKani Statistics Dashboard</title>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {{
                    background-color: #151519;
                    color: #8b8b9c;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    margin: 0;
                    padding: 20px;
                    line-height: 1.6;
                }}
                .chart-container {{
                    margin: 20px auto;
                    padding: 15px;
                    border-radius: 8px;
                    border: 1px solid #1e1e24;
                    background-color: #1a1a1f;
                    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
                }}
                h1 {{
                    text-align: center;
                    color: #ffffff;
                    margin-bottom: 40px;
                    font-size: 2.5em;
                    font-weight: 300;
                }}
                .dashboard-info {{
                    text-align: center;
                    margin-bottom: 30px;
                    color: #888;
                    font-size: 0.9em;
                }}
            </style>
        </head>
        <body>
            <h1>WaniKani Statistics Dashboard</h1>
            <div class="dashboard-info">
                Interactive dashboard showing your WaniKani learning progress over time
            </div>

            <div class="chart-container">{reviews_html}</div>
            <div class="chart-container">{lessons_html}</div>
            <div class="chart-container">{progression_html}</div>
            <div class="chart-container">{apprentice_distribution_html}</div>
            <div class="chart-container">{srs_stage_apprentice_html}</div>
            <div class="chart-container">{srs_stage_guru_html}</div>
            <div class="chart-container">{srs_stage_master_html}</div>
            <div class="chart-container">{srs_stage_enlightened_html}</div>
            <div class="chart-container">{srs_stage_burned_html}</div>
        </body>
    </html>
    """

    # Save to file if output_path is provided
    if output_path:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"Standalone HTML dashboard saved to: {output_path}")

    return html_content


@app.route("/download")
def download_dashboard():
    """Route to download a standalone HTML file."""
    file_names = get_zip_file_names()

    print(f"Found {len(file_names)} zip files in {DATA_DIR}")
    list_of_daily_data = []
    for file_name in file_names:
        daily_data = load_zip(file_name)
        list_of_daily_data.append(daily_data)

    df = get_dataframe(list_of_daily_data)
    df.sort_values(by="date", inplace=True)

    html_content = generate_standalone_html(df)

    response = Response(html_content, content_type="text/html")
    response.headers["Content-Disposition"] = "attachment; filename=wanikani_dashboard.html"
    return response


def render_html(df):
    """Render the DataFrame as HTML with interactive Plotly charts."""
    reviews_html = get_plotly_html(df, "num_reviews", "Daily Reviews", "Number of Reviews")
    lessons_html = get_plotly_html(df, "num_lessons", "Daily Lessons", "Number of Lessons")
    progression_html = get_plotly_html(
        df, "progression", "SRS Progression", "Progression (%)"
    )

    # apprentice distribution chart
    apprentice_distribution_html = get_apprentice_distribution_html(df)

    # srs stages
    srs_stage_apprentice_html = get_plotly_html(
        df, "apprentice", "Apprentice Stage", "Number of Subjects"
    )
    srs_stage_guru_html = get_plotly_html(df, "guru", "Guru Stage", "Number of Subjects")
    srs_stage_master_html = get_plotly_html(
        df, "master", "Master Stage", "Number of Subjects"
    )
    srs_stage_enlightened_html = get_plotly_html(
        df, "enlightened", "Enlightened Stage", "Number of Subjects"
    )
    srs_stage_burned_html = get_plotly_html(
        df, "burned", "Burned Stage", "Number of Subjects"
    )

    # Render HTML with embedded Plotly charts
    html_content = f"""
    <!DOCTYPE html>
    <html>
        <head>
            <title>WaniKani Stats</title>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {{
                    background-color: #151519;
                    color: #8b8b9c;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    margin: 0;
                    padding: 20px;
                }}
                .chart-container {{
                    margin: 20px auto;
                    padding: 10px;
                    border-radius: 5px;
                    border: 1px solid #1e1e24;
                    background-color: #151519;
                }}
                h1 {{
                    text-align: center;
                    color: #8b8b9c;
                    margin-bottom: 30px;
                }}
            </style>
        </head>
        <body>
            <h1>WaniKani Statistics Dashboard</h1>
            <div class="chart-container">{reviews_html}</div>
            <div class="chart-container">{lessons_html}</div>
            <div class="chart-container">{progression_html}</div>
            <div class="chart-container">{apprentice_distribution_html}</div>
            <div class="chart-container">{srs_stage_apprentice_html}</div>
            <div class="chart-container">{srs_stage_guru_html}</div>
            <div class="chart-container">{srs_stage_master_html}</div>
            <div class="chart-container">{srs_stage_enlightened_html}</div>
            <div class="chart-container">{srs_stage_burned_html}</div>
        </body>
    </html>
    """
    return html_content


@app.route("/")
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
    df.sort_values(by="date", inplace=True)

    response = Response(render_html(df), content_type="text/html")
    response.headers["Widget-Content-Type"] = "html"
    response.headers["Widget-Title"] = "WaniKani Statistics"
    return response


@app.route("/health")
def health():
    """Health check endpoint"""
    return {"status": "ok", "service": "wanikani-stats"}


if __name__ == "__main__":
    import sys

    # Check if user wants to generate standalone HTML
    if len(sys.argv) > 1 and sys.argv[1] == "generate":
        output_file = sys.argv[2] if len(sys.argv) > 2 else "wanikani_dashboard.html"

        print("Generating standalone HTML dashboard...")
        file_names = get_zip_file_names()

        print(f"Found {len(file_names)} zip files in {DATA_DIR}")
        list_of_daily_data = []
        for file_name in file_names:
            daily_data = load_zip(file_name)
            list_of_daily_data.append(daily_data)

        df = get_dataframe(list_of_daily_data)
        df.sort_values(by="date", inplace=True)

        generate_standalone_html(df, output_file)
        print(f"✅ Standalone HTML dashboard generated: {output_file}")
        print("📊 You can now open this file in any web browser to view your interactive WaniKani stats!")

    else:
        # Start Flask server
        port = int(sys.argv[1]) if len(sys.argv) > 1 else 8501
        print(f"Starting WaniKani Stats Flask app on port {port}")
        print(f"📊 View dashboard at: http://localhost:{port}")
        print(f"💾 Download standalone HTML at: http://localhost:{port}/download")
        app.run(host="0.0.0.0", port=port, debug=False)
