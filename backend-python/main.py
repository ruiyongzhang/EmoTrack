from flask import Flask, request, jsonify

from upload_to_db import upload_to_db
# from filter_scrape_categorise import filter_scrape_categorise
from new_fsc import new_fsc

app = Flask(__name__)

# 主页
@app.route('/')
def main():
    return "Hi Flask!"

@app.route('/api/handle_file', methods=['POST'])
def handle_file():
    data = request.json
    handle_file = data.get("handle_file", False)
    userUid = data.get("userUid", '')
    
    if handle_file:
        upload_to_db(userUid)
        # handle_file = False
        # print("Hello, reach here")
        return jsonify({"message": "Handling file..."}), 200
    else:
        return jsonify({"message": "No action taken."}), 200

@app.route('/api/handle_data', methods=['POST'])
def handle_data():
    data = request.json
    handle_data = data.get("handle_data", False)
    userUid = data.get("userUid", '')
    startDate = data.get("startDate", '')
    endDate = data.get("endDate", '')
    
    if handle_data:
        new_fsc(userUid, startDate, endDate)
        return jsonify({"message": "Handling data succeed"}), 200
    else:
        return jsonify({"message": "No action taken."}), 200
    

if __name__ == '__main__':
    app.debug=True  # 默认开启debug模式
    # host=0.0.0.0 port=5000
    app.run('0.0.0.0', 5000)
