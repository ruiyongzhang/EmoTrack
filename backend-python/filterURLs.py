import json
from datetime import datetime, timezone
from dateutil import parser

# Load the JSON data
file_path = 'watch-history.json'
with open(file_path, 'r', encoding='utf-8') as file:
    data = json.load(file)

# Define your time range
start_time = datetime.strptime('2024-01-18 00:00:00', '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone.utc)
end_time = datetime.strptime('2024-02-18 00:00:00', '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone.utc)

# Function to parse ISO 8601 formatted string to a datetime object
def parse_iso8601(iso_time_str):
    return parser.isoparse(iso_time_str)

# Filter URLs based on the time range
filter_items = [
    (item['titleUrl'], item['time']) for item in data
    if 'time' in item and start_time <= parse_iso8601(item['time']) <= end_time
]

# Example output or save the URLs to a file
with open('filtered_urls.json', 'w', encoding='utf-8') as output_file:
    json.dump([{'URL': url, 'Time': parse_iso8601(time).strftime('%Y-%m-%d %H:%M:%S')} for url, time in filter_items], output_file, indent=4)