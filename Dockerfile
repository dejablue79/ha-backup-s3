FROM alpine:3.14

RUN apk add --no-cache bash tar gzip jq cron python3 py3-pip
RUN pip3 install awscli
COPY run.sh /run.sh
RUN chmod +x /run.sh
WORKDIR /
CMD [ "/run.sh" ]