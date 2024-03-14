import os, json
from google.cloud import storage

# 指定服务账号密钥文件路径
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "gs://sms-app-project-415923.appspot.com/Files/watch-history.json"

# 创建一个Cloud Storage客户端
client = storage.Client()

# 获取你的存储桶
bucket = client.get_bucket('sms-app-project-415923.appspot.com')

# 创建一个blob对象
blob = bucket.blob('gs://sms-app-project-415923.appspot.com/Files/watch-history.json')

# 读取文件内容到内存
file_contents = blob.download_as_text()

data = json.loads(file_contents)

print(data)