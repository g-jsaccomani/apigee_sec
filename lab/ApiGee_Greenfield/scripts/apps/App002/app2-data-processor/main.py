from flask import Flask
app = Flask(__name__)
@app.route("/")
def process():
    return {"status": "processing", "data": "heavy load"}
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
