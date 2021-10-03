# Improvements/Features:

0- Use get_item instead of table_scan for the stats function.
1- Save time if not passed using PUT.
2- New function to check if calculating stats needed each time a new temperature is added (helper function).
3- Authenticate & authorize devices that are sending temperature data
4- Blue/Green using CodeDeploy.
5- Confine permissions on all of the roles.
6- Add service autoscaling.
7- Separate application's source code and infrastructure repositories
8- Use a web server for production loads, like Nginx. 