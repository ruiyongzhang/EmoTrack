import json
from datetime import datetime, timezone
from dateutil import parser

# Load the JSON data
file_path = '/Users/zhangruiyong/scraper/watch-history.json'
with open(file_path, 'r', encoding='utf-8') as file:
    data = json.load(file)

# Define your time range
start_time = datetime.strptime('2024-01-18 00:00:00', '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone.utc)
end_time = datetime.strptime('2024-02-18 00:00:00', '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone.utc)

# Function to parse ISO 8601 formatted string to a datetime object
def parse_iso8601(iso_time_str):
    return parser.isoparse(iso_time_str)

# Filter URLs based on the time range
urls_in_range = [
    item['titleUrl'] for item in data
    if 'time' in item and start_time <= parse_iso8601(item['time']) <= end_time
]

# Example output or save the URLs to a file
with open('/Users/zhangruiyong/scraper/youtube-scraper/filtered_urls.txt', 'w', encoding='utf-8') as output_file:
    for url in urls_in_range:
        output_file.write(url + '\n')
