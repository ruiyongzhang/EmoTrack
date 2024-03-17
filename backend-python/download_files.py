import firebase_admin
from firebase_admin import credentials, storage
from google.cloud import storage as gcs
from google.oauth2 import service_account

cred = credentials.Certificate("sms-app-project-415923-5cd00cff4d32.json")
firebase_admin.initialize_app(cred, {'storageBucket': 'sms-app-project-415923.appspot.com'})

gcs_credentials = service_account.Credentials.from_service_account_file("sms-app-project-415923-5cd00cff4d32.json")
bucket = storage.bucket()
blob = bucket.blob('Files/watch-history.json')
gcs.Client(credentials=gcs_credentials).bucket(bucket.name).blob(blob.name).download_to_filename('watch-history.json')