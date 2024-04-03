import firebase_admin, json
from firebase_admin import credentials, firestore, storage
from google.cloud import storage as gcs

def new_upload_to_db():
  # Use the application default credentials.
  cred = credentials.ApplicationDefault()

  firebase_admin.initialize_app(cred, {'storageBucket': 'sms-app-project-415923.appspot.com'})
  db = firestore.client()

  gcs_client = gcs.Client(credentials=cred)

  bucket_name = 'sms-app-project-415923.appspot.com'
  bucket = storage.bucket(bucket_name)
  blobs = gcs_client.list_blobs(bucket_name, prefix='Files/')
  uids = set([blob.name.split('/')[1] for blob in blobs if '/' in blob.name])
  for uid in uids:
      # 枚举指定用户uid文件夹内的所有JSON文件
      user_blobs = bucket.list_blobs(prefix=f'Files/{uid}/')
      for user_blob in user_blobs:
          if user_blob.name.endswith('.json'):
              # 读取JSON文件内容
              json_data = user_blob.download_as_text()
              data = json.loads(json_data)
              
              # 使用用户uid作为Firestore文档ID，上传JSON内容
              doc_ref = db.collection('Users').document(uid).collection('YouTube Watch History')
              
              for item in data:
                  if "title" in item and "titleUrl" in item and "time" in item:
                      video_info = {'title': item['title'], 'titleUrl': item['titleUrl'], 'time': item['time']}
                      doc_name = item['time']
                      doc_ref.document(doc_name).set(video_info)
                      
                      print(f'Uploaded data from {user_blob.name} to Firestore document {doc_name}')