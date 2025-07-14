FROM ealen/echo-server:latest

ENTRYPOINT [ "node", "webserver", "--port 8080" ]
