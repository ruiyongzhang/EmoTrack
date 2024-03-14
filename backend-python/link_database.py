from google.cloud import datastore

# 设置你的 Google Cloud 项目 ID
project_id = "sms-app-project-415923"

# 连接 Datastore
client = datastore.Client(project=project_id)

# 创建一个实体
entity = datastore.Entity(key=client.key("MyEntity"))
entity.update({
    "name": "John",
    "age": 30,
    "email": "john@example.com"
})

# 保存实体
client.put(entity)

# 查询实体
query = client.query(kind="MyEntity")
query.add_filter("name", "=", "John")
result = list(query.fetch())

# 打印结果
for entity in result:
    print(entity)
