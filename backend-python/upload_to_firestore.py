import firebase_admin
from firebase_admin import credentials, storage
from google.cloud import storage as gcs, firestore
from google.oauth2 import service_account
import json

# 初始化Cloud Storage和Firestore客户端
gcs_client = gcs.Client()
firestore_client = firestore.Client()
cred = credentials.Certificate("sms-app-project-415923-5cd00cff4d32.json")
firebase_admin.initialize_app(cred, {'storageBucket': 'sms-app-project-415923.appspot.com'})

def upload_json_to_firestore():
    gcs_credentials = service_account.Credentials.from_service_account_file("sms-app-project-415923-5cd00cff4d32.json")
    bucket = storage.bucket()
    blob = bucket.blob('Files/watch-history.json')
    json_data = gcs.Client(credentials=gcs_credentials).bucket(bucket.name).blob(blob.name).download_as_text()
    # # 从Cloud Storage读取JSON文件
    # bucket = gcs_client.bucket(bucket_name)
    # blob = bucket.blob(source_blob_name)
    # json_data = blob.download_as_text()

    # 解析JSON数据
    data = json.loads(json_data)

    # 假设data是一个包含多个用户信息的列表
    for user_info in data:
        # 使用上传用户的独一无二信息作为文档ID
        user_id = user_info['user_id']
        doc_ref = firestore_client.collection('users').document(user_id)

        # 将用户信息写入Firestore
        doc_ref.set(user_info)
        print(f'Data for user {user_id} uploaded to Firestore')

# 示例：调用函数
bucket_name = 'sms-app-project-415923.appspot.com'
source_blob_name = 'gs://sms-app-project-415923.appspot.com/Files/watch-history.json'
upload_json_to_firestore()
