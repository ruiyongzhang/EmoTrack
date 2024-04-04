# 使用官方Python镜像作为基础镜像
FROM python:3.8-slim

# 安装Google Chrome
RUN apt-get update && apt-get install -y wget gnupg2 && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' && \
    apt-get update && apt-get install -y google-chrome-stable

# 将依赖文件复制到容器中并安装依赖
COPY requirements.txt ./
RUN pip install -r requirements.txt

# 复制本地代码到容器内
COPY . ./

# 运行gunicorn作为Web服务器
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 main:app
