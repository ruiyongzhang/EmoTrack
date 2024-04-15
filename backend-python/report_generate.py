from google.cloud import firestore
from google.oauth2 import service_account
from datetime import datetime, timedelta, timezone
import re

gcs_credentials = service_account.Credentials.from_service_account_file("sms-app-project-415923-5cd00cff4d32.json")
db = firestore.Client(credentials=gcs_credentials)


def update_mood_status(mood_status_counts, mood_date, mood_status):
  # mood_status_counts = {}
  # 检查日期是否已经存在
  if mood_date not in mood_status_counts:
      # 如果不存在，初始化该日期的心情状态计数
      mood_status_counts[mood_date] = {'Same': 0, 'Better': 0, 'Worse': 0}
  
  # 更新对应日期的心情状态计数
  mood_status_counts[mood_date][mood_status] += 1
  return mood_status_counts


async def report_generate(uid):
  report_ref = db.collection('Users').document(uid).collection('Report')
  mood_ref = db.collection('Users').document(uid).collection('Mood Records')
  mood_docs = mood_ref.stream()
  
  mood_status_counts = {}
  day_watch_number_counts = {}
  
  for mood_doc in mood_docs:
    mood_data = mood_doc.to_dict()
    if 'After Watch Mood' in mood_data and 'Before Watch Mood' in mood_data:
      # print(f'Mood doc: {mood_doc.id}')
      before_mood = mood_data.get('Before Watch Mood', 'null')
      after_mood = mood_data.get('After Watch Mood', 'null')
      mood_start_time = mood_data.get('Start Watch Time', 'null')
      mood_end_time = mood_data.get('Stop Watch Time', 'null')
      mood_date = datetime.fromisoformat(str(mood_start_time)).strftime('%Y-%m-%d')
      # print(f'Mood Start time: {mood_start_time}')
      # print(f'Mood End time: {mood_end_time}')
      start_time = datetime.strptime(mood_start_time, '%Y-%m-%d %H:%M:%S')
      end_time = datetime.strptime(mood_end_time, '%Y-%m-%d %H:%M:%S')
    
      watch_total_number = 0
      
      category_counts = {}
      
      if (before_mood == 'Good' and after_mood == 'Good') or (before_mood == 'Okay' and after_mood == 'Okay') or (before_mood == 'Not good' and after_mood == 'Not good'):
        mood_status = 'Same'
      elif (before_mood == 'Good' and after_mood == 'Okay') or (before_mood == 'Okay' and after_mood == 'Not good') or (before_mood == 'Good' and after_mood == 'Not good'):
        mood_status = 'Worse'
      elif (before_mood == 'Okay' and after_mood == 'Good') or (before_mood == 'Not good' and after_mood == 'Okay') or (before_mood == 'Not good' and after_mood == 'Good'):
        mood_status = 'Better'
      
      
        
      history_ref = db.collection('Users').document(uid).collection('YouTube Watch History')
      history_docs = history_ref.stream()
      for history_doc in history_docs:
        video_data = history_doc.to_dict()
        watch_time = video_data.get('time', 'null')
        watch_time = datetime.strptime(watch_time, "%Y-%m-%d %H:%M:%S")
        
        # print(f'Start time: {start_time}')
        # print(f'End time: {end_time}')
        if start_time <= watch_time <= end_time:
          watch_total_number += 1
          
          # print(f'watch time: {watch_time}')
          # print('yeahyeahyeah')
          video_category = video_data.get('category', 'null')
          if str(video_category) in category_counts:
            category_counts[str(video_category)] += 1
          else:
            category_counts[str(video_category)] = 1
      
      update_mood_status(mood_status_counts, mood_date, mood_status)
      
      if mood_date in day_watch_number_counts:
        day_watch_number_counts[mood_date] += watch_total_number
      else:
        day_watch_number_counts[mood_date] = watch_total_number
        
      
      
      mood_ref.document(mood_doc.id).update({'Status': mood_status})
      
      report_ref.document(mood_date).collection('Details').document(mood_doc.id).set({'Start Watching Time': mood_start_time, 'Stop Watching Time': mood_end_time, 'Mood Status': mood_status, 'Total watched video number': watch_total_number}, merge=True)
      
      for category, count in category_counts.items():
        category = re.sub(r'\W+', '', category)
        # category = str(category.replace("-", "_"))
        category = str(category)
        report_ref.document(mood_date).collection('Details').document(mood_doc.id).update({category: count})
      
      for mood_date, number in day_watch_number_counts.items():
        report_ref.document(mood_date).collection('Summary').document(mood_date).set({'Today_watched_video_number': number}, merge=True)
      
      for mood_date, status_counts in mood_status_counts.items():
        for mood_status, count in status_counts.items():
          report_ref.document(mood_date).collection('Summary').document(mood_date).update({mood_status: count})
      
      print(f'Finish report for {mood_date}')
  
  return 'Detailed and Summary Report generated!'
  


# uid = 'qKtXmGL42mZAfwSYEnsLdDmA1lF2'
# report_generate(uid)
# report_summary(uid)
  
