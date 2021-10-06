import json
import boto3
import os
from flask import Flask, request
from flask.wrappers import Response
app = Flask(__name__)

# Set allowance to serve from all IP addresses and ports
if __name__ == '__main__':
	app.run(host='0.0.0.0', port=80)

# Set table name from environment variables, the table name is a variable because it gets created in the provisioning stage, so that the code doesn't create it each time it runs.
try:
    table_name = os.environ['TABLE_NAME']
except:
    print('Please set the environment variable "TABLE_NAME" to be the, you know, table name')

dbclient = boto3.client('dynamodb') 
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(table_name)


#Sample GET response with 'Hello!' for testing basic functions
@app.route('/api')
def index():
    return {'message': 'Hello!'}

# Function to PUT through /api/temperature, payload format:
# {"sensorID": "107","temperature": "200","time": "2012-MM-DD HH:MM:SS"}

@app.route('/api/temperature', methods=['PUT'])
def insternewtemp():
    new_temp = request.json
    response = dbclient.put_item(
    TableName=table_name,
    Item={
        'time': {
            'S': new_temp['time']},
        
        'sensorID':
           { 'S': new_temp['sensorID']},

        'temperature':
            {'S': new_temp['temperature']}

            }
        )
    return 'Ok'


# Function to return the Maximum, Minimum and Average based on collecting all the temperatures from all the table's items using table.scan()
#Return sample: {"Maximum": 30, "Minimum": 10, "Average": 15}
# TODO: New function with data validation for every key and value inserted. 
@app.route('/api/stats')
def stats():
    all_temps = []
    response = table.scan()
    
    for object in response['Items']:
        all_temps.append(int(object['temperature']))
        
    try:
        maximum = max(all_temps)
    except:
        return 'No data inserted yet!'
    return {"Maximum": int(max(all_temps)), "Minimum": int(min(all_temps)),"Average": round(sum(all_temps)/len(all_temps))}    

