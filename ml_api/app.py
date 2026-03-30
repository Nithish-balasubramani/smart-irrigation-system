from flask import Flask, request, jsonify
import joblib

app = Flask(__name__)

model = joblib.load("model.pkl")


@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json(force=True)

    moisture = data['moisture']
    temp = data['temperature']

    result = model.predict([[moisture, temp]])

    return jsonify({
        "prediction": int(result[0]),
        "motor": "ON" if int(result[0]) == 1 else "OFF"
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
