import firebase_admin
from firebase_admin import credentials, storage
from google.cloud import storage as gcs, firestore
from google.oauth2 import service_account
import json

separated_data = {
    "title": [],
    "titleUrl": [],
    "time": [],
}

gcs_credentials = service_account.Credentials.from_service_account_file("sms-app-project-415923-5cd00cff4d32.json")
gcs_client = gcs.Client(credentials=gcs_credentials)

cred = credentials.Certificate("sms-app-project-415923-5cd00cff4d32.json")
firebase_admin.initialize_app(cred, {'storageBucket': 'sms-app-project-415923.appspot.com'})
firestore_client = firestore.Client(credentials=gcs_credentials)

gcs_credentials = service_account.Credentials.from_service_account_file('sms-app-project-415923-5cd00cff4d32.json')
bucket_name = 'sms-app-project-415923.appspot.com'
bucket = storage.bucket(bucket_name)
blobs = gcs_client.list_blobs(bucket_name, prefix='Files/')
prefixes = set([blob.name.split('/')[1] for blob in blobs if '/' in blob.name])
for uid in prefixes:
    # 枚举指定用户uid文件夹内的所有JSON文件
    user_blobs = bucket.list_blobs(prefix=f'Files/{uid}/')
    for user_blob in user_blobs:
        if user_blob.name.endswith('.json'):
            # 读取JSON文件内容
            json_data = user_blob.download_as_text()
            data = json.loads(json_data)
            
            # 使用用户uid作为Firestore文档ID，上传JSON内容
            doc_ref = firestore_client.collection('Users Watching History Data').document(uid)
            
            for item in data:
                if "title" in item and "titleUrl" in item and "time" in item:
                    separated_data['title'].append(item['title'])
                    separated_data['titleUrl'].append(item['titleUrl'])
                    separated_data['time'].append(item['time'])
            
            data = {'title': separated_data['title'], 'titleUrl': separated_data['titleUrl'], 'time': separated_data['time']}
            doc_ref.set(data)
            
            print(f'Uploaded data from {user_blob.name} to Firestore document {uid}')
            
            