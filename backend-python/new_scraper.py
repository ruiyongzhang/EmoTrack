from googleapiclient.discovery import build

# 用你的API密钥替换下面的YOUR_API_KEY
api_key = 'AIzaSyBZrV-xxAvaJtjsozjp4vo6WdrEvm8DNH4'
youtube = build('youtube', 'v3', developerKey=api_key)

# 用你想要获取信息的视频ID替换下面的VIDEO_ID
video_id = 'xLTCivIB4kU'

# 执行API请求获取视频的信息
request = youtube.videos().list(
    part="snippet",
    id=video_id
)
response = request.execute()

# 从响应中提取视频简介
video_description = response['items'][0]['snippet']['description']
video_title = response['items'][0]['snippet']['title']
print(video_title)
print(video_description)
