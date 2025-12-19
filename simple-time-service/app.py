from flask import Flask, request
from datetime import datetime
import json

app = Flask(__name__)

@app.route("/")
def home():
    current_time = datetime.utcnow().isoformat() + "Z"
    visitor_ip = request.remote_addr

    response = {
        "timestamp": current_time,
        "ip": visitor_ip
    }

    return app.response_class(
        response=json.dumps(response, indent=2),
        status=200,
        mimetype='application/json'
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

