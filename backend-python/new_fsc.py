import json, sys, os
from openai import OpenAI
from datetime import datetime, timezone
from dateutil import parser
from google.cloud import firestore
from google.oauth2 import service_account
from google.api_core.exceptions import DeadlineExceeded
from googleapiclient.discovery import build
from urllib.parse import urlparse, parse_qs


api_key = 'AIzaSyBZrV-xxAvaJtjsozjp4vo6WdrEvm8DNH4'
youtube = build('youtube', 'v3', developerKey=api_key)
os.environ["OPENAI_API_KEY"] = "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"

client = OpenAI(
    # Defaults to os.environ.get("OPENAI_API_KEY")
    api_key=os.environ.get("OPENAI_API_KEY") 
)

try:
  gcs_credentials = service_account.Credentials.from_service_account_file("sms-app-project-415923-5cd00cff4d32.json")
  db = firestore.Client(credentials=gcs_credentials)
except Exception as e:
  print(f"An unexpected error occurred: {e}")
  
# Function to parse ISO 8601 formatted string to a datetime object
def convert_time(iso_time_str):
    return parser.isoparse(iso_time_str)
  
def new_fsc(uid, startDate, endDate):
  # Define your time range
  start_time = datetime.strptime(startDate, '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone.utc)
  end_time = datetime.strptime(endDate, '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone.utc)
  
  history_ref = db.collection('Users').document(uid).collection('YouTube Watch History')
  history_docs = history_ref.stream()
  
  for history_doc in history_docs:
      if start_time <= convert_time(history_doc.id) <= end_time:
        
        video_data = history_doc.to_dict()
        # video_title = video_data.get('title', 'null')
        watch_time = video_data.get('time', 'null')
        video_url = video_data.get('titleUrl', 'null')
        video_url = video_url.strip()
        
        
        if 'description' in video_data and 'category' in video_data:
          if video_data['description'] or video_data['category']:
            print('Already has description and category')
            continue
          else:
            print('Description and category is empty')
        else:
            print('Description and category does not exist')
        
        # Scrape the title and description
        video_title, video_description = new_scrape_info(video_url)
        
        # Categorise the video with ChatGPT
        content = "Categorise the YouTube video in one word accoding to its title and description, the title is: " + video_title + " and the description is: " + video_description
        chat_completion = client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": content}]
        )
        video_category = chat_completion.choices[0].message.content
        
        # upload to database
        history_ref.document(history_doc.id).update({'title':video_title, 'description': video_description, 'category': video_category})
        
        print(video_title)
        print('Upload succeed')
        

def new_scrape_info(url):
  parsed_url = urlparse(url)
  if parsed_url.netloc == 'www.youtube.com':
    parsed_qs = parse_qs(parsed_url.query)
    video_id = parsed_qs.get("v", [None])[0]
    
    request = youtube.videos().list(
        part="snippet",
        id=video_id
    )
    response = request.execute()
    
    if response['items']:
      video_title = response['items'][0]['snippet']['title']
      video_description = response['items'][0]['snippet']['description']
    else:
      video_title = 'null'
      video_description = 'null'
      
    return video_title, video_description
          
uid = 'qKtXmGL42mZAfwSYEnsLdDmA1lF2'
startDate = '2024-03-01 00:00:00'
endDate = '2024-04-02 00:00:00'
new_fsc(uid, startDate, endDate)