from quart import Quart, request, jsonify
from quart_cors import cors

from upload_to_db import upload_to_db
from new_fsc import new_fsc
from report_generate import report_generate

app = Quart(__name__)
app = cors(app, 
           allow_origin="https://sms-app-project-415923.web.app", 
           allow_methods=["GET", "POST", "OPTIONS"],
           allow_credentials=True)

# 主页
@app.route('/')
def main():
    return "Hi Quart!"

@app.route('/api/handle_file', methods=['POST'])
async def handle_file():
    data = await request.json
    handle_file = data.get("handle_file", False)
    userUid = data.get("userUid", '')
    
    if handle_file:
        upload_to_db(userUid)
        
        return jsonify({"message": "Handling file..."}), 200
    else:
        return jsonify({"message": "No action taken."}), 200

@app.route('/api/handle_data', methods=['POST'])
async def handle_data():
    data = await request.json
    handle_data = data.get("handle_data", False)
    userUid = data.get("userUid", '')
    startDate = data.get("startDate", '')
    endDate = data.get("endDate", '')
    
    if handle_data:
        message = await new_fsc(userUid, startDate, endDate)
        print(message)
        message = await report_generate(userUid)
        print(message)
        return jsonify({"message": "Handling data succeed"}), 200
    else:
        return jsonify({"message": "No action taken."}), 200
    

if __name__ == '__main__':
    app.debug=True  # 默认开启debug模式
    # host=0.0.0.0 port=5000
    app.run('0.0.0.0', 5000)
