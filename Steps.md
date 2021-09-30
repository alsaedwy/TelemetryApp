# Steps:

0- To Self: Don't forget the environment variables: (export FLASK_APP=main.py - export FLASK_ENV=development )

1- Create the APIs locally using dictionaries, and create the logic to return max, min and average temperatures. - Done.
2- Add DynamoDB connection with inserting the data into the table(s) instead of local dictionaries. - Done.
3- Query the DynamoDB table for stats, instead of local dictionary. - Done. 
4- Make 'Table Name' a variable, so that the code can dynamically work with any table. - Done.
5- Containerise the application. - Done.
6- 