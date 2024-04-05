from google.cloud import firestore
from google.oauth2 import service_account
from datetime import datetime, timedelta, timezone

from new_fsc import convert_time

gcs_credentials = service_account.Credentials.from_service_account_file("sms-app-project-415923-5cd00cff4d32.json")
db = firestore.Client(credentials=gcs_credentials)

async def report_generate(uid):
  report_ref = db.collection('Users').document(uid).collection('Report')
  mood_ref = db.collection('Users').document(uid).collection('Mood Records')
  mood_docs = mood_ref.stream()
  history_ref = db.collection('Users').document(uid).collection('YouTube Watch History')
  history_docs = history_ref.stream()
  
  
  for mood_doc in mood_docs:
    mood_data = mood_doc.to_dict()
    if 'After Watch Mood' in mood_data and 'Before Watch Mood' in mood_data:
      before_mood = mood_data.get('Before Watch Mood', 'null')
      after_mood = mood_data.get('After Watch Mood', 'null')
      mood_start_time = mood_data.get('Start Watch Time', 'null')
      mood_end_time = mood_data.get('Stop Watch Time', 'null')
      mood_date = datetime.fromisoformat(str(mood_start_time)).strftime('%Y-%m-%d')
      category_counts = {}
      
      if (before_mood == 'Good' and after_mood == 'Good') or (before_mood == 'Okay' and after_mood == 'Okay') or (before_mood == 'Not good' and after_mood == 'Not good'):
        mood_status = 'Same'
      elif (before_mood == 'Good' and after_mood == 'Okay') or (before_mood == 'Okay' and after_mood == 'Not good') or (before_mood == 'Good' and after_mood == 'Not good'):
        mood_status = 'Worse'
      elif (before_mood == 'Okay' and after_mood == 'Good') or (before_mood == 'Not good' and after_mood == 'Okay') or (before_mood == 'Not good' and after_mood == 'Good'):
        mood_status = 'Better'
      
      # start_time = datetime.strptime(mood_start_time, '%Y-%m-%d %H:%M:%S')
      # end_time = datetime.strptime(mood_end_time, '%Y-%m-%d %H:%M:%S')
      start_time = datetime.strptime(str(mood_start_time), '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone.utc)
      end_time = datetime.strptime(str(mood_end_time), '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone.utc)
      watch_total_number = 0
      for history_doc in history_docs:
        # watch_time = datetime.strptime(history_doc.id, '%Y-%m-%dT%H:%M:%S.%fZ')
        
        if start_time <= convert_time(history_doc.id) <= end_time:
          watch_total_number += 1
          video_data = history_doc.to_dict()
          video_category = video_data.get('category', 'null')
          if video_category in category_counts:
                category_counts[video_category] += 1
          else:
              category_counts[video_category] = 1
      
      mood_ref.document(mood_doc.id).update({'Status': mood_status})
      
      report_ref.document(mood_date).collection(mood_doc.id).document(mood_doc.id).set({'Start Watching Time': mood_start_time, 'Stop Watching Time': mood_end_time, 'Mood Status': mood_status, 'Total watched video number': watch_total_number})
      for category, count in category_counts.items():
        report_ref.document(mood_date).collection(mood_doc.id).document(mood_doc.id).update({category: count})
      print(f'Finish report for {mood_date}')
  return 'Report generated!'
  
  
# def report_generate(uid, startDate, endDate):
#   report_ref = db.collection('Users').document(uid).collection('Report')
#   start_date = datetime.strptime(startDate, '%Y-%m-%d %H:%M:%S')
#   end_date = datetime.strptime(endDate, '%Y-%m-%d %H:%M:%S')
  
#   delta = timedelta(days=1)
#   while start_date <= end_date:
#     current_date = start_date.strftime('%Y-%m-%d')
#     start_date += delta
    
      
uid = 'qKtXmGL42mZAfwSYEnsLdDmA1lF2'
# report_generate(uid)
      