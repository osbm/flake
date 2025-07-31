import zipfile
import json
from pathlib import Path
from flask import Flask, render_template_string, Response
import pandas as pd
from datetime import datetime

app = Flask(__name__)
DATA_DIR = Path("/var/lib/wanikani-logs")

print("Starting WaniKani Flask service")

def load_data():
    """Load and process WaniKani data from zip files"""
    records = []
    try:
        for zip_path in sorted(DATA_DIR.glob("wanikani_data_*.zip")):
            print(f"Processing {zip_path.name}...")
            with zipfile.ZipFile(zip_path) as z:
                for name in z.namelist():
                    if name.endswith('.json'):
                        try:
                            with z.open(name) as f:
                                data = json.load(f)
                                date = zip_path.stem.split("_")[-1]
                                # Extract relevant data from the JSON structure
                                record = {
                                    "date": date,
                                    "available_lessons": data.get("lessons", {}).get("available", 0) if isinstance(data.get("lessons"), dict) else 0,
                                    "level": data.get("level", 0),
                                    "reviews_available": data.get("reviews", {}).get("available", 0) if isinstance(data.get("reviews"), dict) else 0,
                                }
                                records.append(record)
                        except (json.JSONDecodeError, KeyError, TypeError) as e:
                            print(f"Error processing {name}: {e}")
                            continue
    except Exception as e:
        print(f"Error loading data: {e}")

    return pd.DataFrame(records) if records else pd.DataFrame()

def generate_chart_html(df):
    """Generate HTML with embedded chart using Chart.js"""
    if df.empty:
        return "<p>No data available</p>"

    # Prepare data for Chart.js
    dates = df['date'].tolist()
    levels = df['level'].tolist()
    lessons = df['available_lessons'].tolist()
    reviews = df['reviews_available'].tolist()

    chart_html = f"""
    <div style="width: 100%; height: 300px;">
        <canvas id="wanikaniChart"></canvas>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        const ctx = document.getElementById('wanikaniChart').getContext('2d');
        const chart = new Chart(ctx, {{
            type: 'line',
            data: {{
                labels: {dates},
                datasets: [{{
                    label: 'Level',
                    data: {levels},
                    borderColor: 'rgb(75, 192, 192)',
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    yAxisID: 'y'
                }}, {{
                    label: 'Available Lessons',
                    data: {lessons},
                    borderColor: 'rgb(255, 99, 132)',
                    backgroundColor: 'rgba(255, 99, 132, 0.2)',
                    yAxisID: 'y1'
                }}, {{
                    label: 'Available Reviews',
                    data: {reviews},
                    borderColor: 'rgb(54, 162, 235)',
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    yAxisID: 'y1'
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                interaction: {{
                    mode: 'index',
                    intersect: false,
                }},
                scales: {{
                    x: {{
                        display: true,
                        title: {{
                            display: true,
                            text: 'Date'
                        }}
                    }},
                    y: {{
                        type: 'linear',
                        display: true,
                        position: 'left',
                        title: {{
                            display: true,
                            text: 'Level'
                        }}
                    }},
                    y1: {{
                        type: 'linear',
                        display: true,
                        position: 'right',
                        title: {{
                            display: true,
                            text: 'Lessons/Reviews'
                        }},
                        grid: {{
                            drawOnChartArea: false,
                        }},
                    }}
                }}
            }}
        }});
    </script>
    """
    return chart_html

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 16px;
            background: transparent;
        }
        .stats-container {
            display: grid;
            gap: 16px;
        }
        .stat-card {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            padding: 12px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .stat-value {
            font-size: 24px;
            font-weight: bold;
            color: #00d4aa;
        }
        .stat-label {
            font-size: 14px;
            color: rgba(255, 255, 255, 0.8);
            margin-top: 4px;
        }
        .chart-container {
            margin-top: 16px;
        }
        .no-data {
            text-align: center;
            color: rgba(255, 255, 255, 0.6);
            padding: 32px;
        }
    </style>
</head>
<body>
    <div class="stats-container">
        {% if has_data %}
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 12px; margin-bottom: 16px;">
            <div class="stat-card">
                <div class="stat-value">{{ current_level }}</div>
                <div class="stat-label">Current Level</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{{ available_lessons }}</div>
                <div class="stat-label">Lessons</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{{ available_reviews }}</div>
                <div class="stat-label">Reviews</div>
            </div>
        </div>
        <div class="chart-container">
            {{ chart_html|safe }}
        </div>
        {% else %}
        <div class="no-data">
            <p>📚 No WaniKani data available</p>
            <p style="font-size: 12px;">Check if data files exist in {{ data_dir }}</p>
        </div>
        {% endif %}
    </div>
</body>
</html>
"""

@app.route('/')
def index():
    """Main endpoint for Glance extension"""
    df = load_data()

    # Prepare template variables
    template_vars = {
        'has_data': not df.empty,
        'data_dir': str(DATA_DIR),
        'chart_html': '',
        'current_level': 0,
        'available_lessons': 0,
        'available_reviews': 0
    }

    if not df.empty:
        # Get latest stats
        latest = df.iloc[-1]
        template_vars.update({
            'current_level': int(latest['level']),
            'available_lessons': int(latest['available_lessons']),
            'available_reviews': int(latest['reviews_available']),
            'chart_html': generate_chart_html(df)
        })

    html = render_template_string(HTML_TEMPLATE, **template_vars)

    # Create response with Glance extension headers
    response = Response(html, mimetype='text/html')
    response.headers['Widget-Title'] = '📚 WaniKani Stats'
    response.headers['Widget-Content-Type'] = 'html'

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
