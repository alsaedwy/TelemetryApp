FROM python:3-alpine

COPY . .

WORKDIR ./TelemetryApp

RUN pip3 install -r requirements.txt

ENV TABLE_NAME=TelemetryApp
ENV FLASK_APP=main.py
ENV FLASK_ENV=development
ENV AWS_DEFAULT_REGION=eu-west-1

CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0","--port=80"]
