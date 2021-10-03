FROM python:3-alpine

COPY . .

WORKDIR ./TelemetryApp

RUN pip3 install -r requirements.txt

ENV TABLE_NAME=$TABLE_NAME
ENV AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
ENV FLASK_ENV=$FLASK_ENV
ENV FLASK_APP=main.py

CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0","--port=80"]
