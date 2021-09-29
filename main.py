import json
import boto3
from flask import Flask, jsonify, request
app = Flask(__name__)

dbclient = boto3.client('dynamodb') 

#Sample GET response with 'Hello!' for testing basic functions
@app.route('/api')
def index():
    return jsonify({'message': 'Hello!'})

# Function to PUT through /api/temperature, payload format:
# {“sensorId”: “101”, “temperature”: “12”, “time”: “YYYY-MM-DD HH:MM:SS”}
list = []

@app.route('/api/temperature', methods=['PUT'])
def insternewtemp():
    new_temp = request.json
    list.append(new_temp)
    return {"temps": list}
    
    # new_temp = {request}
    # list.append(new_temp)

    # return jsonify({'completelist': list})
    

    