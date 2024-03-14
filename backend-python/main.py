from flask import Flask

app = Flask(__name__)

# 主页
@app.route('/')
def main():
    return "Hi Flask!"

if __name__ == '__main__':
    app.debug=True  # 默认开启debug模式
    # host=0.0.0.0 port=5000
    app.run('0.0.0.0', 5000)
