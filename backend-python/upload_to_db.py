import firebase_admin
from firebase_admin import credentials, storage, get_app
from google.cloud import storage as gcs, firestore
from google.oauth2 import service_account
import json
from dateutil import parser, tz

def convert_time_str(iso_time_str):
    time_utc = parser.isoparse(iso_time_str)
    london_tz = tz.gettz('Europe/London')
    dt_uk = time_utc.astimezone(london_tz)
    dt_uk_str = dt_uk.strftime('%Y-%m-%d %H:%M:%S')
    return dt_uk_str

def upload_to_db(userUid):
    
    
    gcs_credentials = service_account.Credentials.from_service_account_file("sms-app-project-415923-5cd00cff4d32.json")
    gcs_client = gcs.Client(credentials=gcs_credentials)
    firestore_client = firestore.Client(credentials=gcs_credentials)
    
    try:
        get_app()
    except ValueError as e:
        cred = credentials.Certificate("sms-app-project-415923-5cd00cff4d32.json")
        firebase_admin.initialize_app(cred, {'storageBucket': 'sms-app-project-415923.appspot.com'})
    
    
    bucket_name = 'sms-app-project-415923.appspot.com'
    bucket = storage.bucket(bucket_name)
    blobs = gcs_client.list_blobs(bucket_name, prefix='Files/')
    uids = set([blob.name.split('/')[1] for blob in blobs if '/' in blob.name])
    for uid in uids:
        
        if userUid == str(uid):
            # 枚举指定用户uid文件夹内的所有JSON文件
            user_blobs = bucket.list_blobs(prefix=f'Files/{uid}/')
            for user_blob in user_blobs:
                if user_blob.name.endswith('.json'):
                    # 读取JSON文件内容
                    json_data = user_blob.download_as_text()
                    data = json.loads(json_data)
                    
                    for item in data:
                        if "titleUrl" in item and "time" in item:
                            
                            history_ref = firestore_client.collection('Users').document(uid).collection('YouTube Watch History')
                            # history_docs = history_ref.stream()
                            # if any(item['time'] == history_doc.id for history_doc in history_docs):
                            #     print('Already uploaded this history!')
                            #     continue
                            
                            video_info = {'titleUrl': item['titleUrl'], 'time': convert_time_str(item['time'])}
                            doc_name = item['time']
                            history_ref.document(doc_name).set(video_info, merge=True)
                    
                            print(f'Uploaded data from {user_blob.name} to Firestore document {doc_name}')
        print('Finish user ${uid}!')
                
# upload_to_db()