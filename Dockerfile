FROM python:3-alpine
RUN apk add --no-cache curl
WORKDIR /app
COPY probe.sh /app/
RUN chmod +x /app/probe.sh
EXPOSE 8080
CMD ["/app/probe.sh"]
