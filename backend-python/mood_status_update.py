from google.cloud import firestore
from google.oauth2 import service_account

gcs_credentials = service_account.Credentials.from_service_account_file("sms-app-project-415923-5cd00cff4d32.json")
db = firestore.Client(credentials=gcs_credentials)

def mood_status_update(uid):
  mood_ref = db.collection('Users').document(uid).collection('Mood Records')
  mood_docs = mood_ref.stream()
  
  for mood_doc in mood_docs:
    mood_data = mood_doc.to_dict()
    if 'After Watch Mood' in mood_data and 'Before Watch Mood' in mood_data:
      before_mood = mood_data.get('Before Watch Mood', 'null')
      after_mood = mood_data.get('After Watch Mood', 'null')
      
      if (before_mood == 'Good' and after_mood == 'Good') or (before_mood == 'Okay' and after_mood == 'Okay') or (before_mood == 'Not good' and after_mood == 'Not good'):
        mood_status = 'Same'
      elif (before_mood == 'Good' and after_mood == 'Okay') or (before_mood == 'Okay' and after_mood == 'Not good') or (before_mood == 'Good' and after_mood == 'Not good'):
        mood_status = 'Worse'
      elif (before_mood == 'Okay' and after_mood == 'Good') or (before_mood == 'Not good' and after_mood == 'Okay') or (before_mood == 'Not good' and after_mood == 'Good'):
        mood_status = 'Better'
      
      mood_ref.document(mood_doc.id).update({'Status': mood_status})
      
uid = 'qKtXmGL42mZAfwSYEnsLdDmA1lF2'
mood_status_update(uid)
      