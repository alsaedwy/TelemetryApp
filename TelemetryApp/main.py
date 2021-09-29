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
# {"sensorId": "101", "temperature": "12", "time": "YYYY-MM-DD HH:MM:SS"}
list = [{"sensorId": "101", "temperature": "12", "time": "YYYY-MM-DD HH:MM:SS"}, {"sensorId": "102", "temperature": "14", "time": "YYYY-MM-DD HH:MM:SS"}]

@app.route('/api/temperature', methods=['PUT'])
def insternewtemp():
    new_temp = request.json
    list.append(new_temp)
    return 'Ok'

#{"Maximum": 30, "Minimum": 10, "Average": 15}
@app.route('/api/stats')
def stats():
    all_temps = []
    for object in list:
        all_temps.append(int(object['temperature']))
    return {"Maximum": int(max(all_temps)), "Minimum": int(min(all_temps)),"Average": int(sum(all_temps)/len(all_temps))}    

