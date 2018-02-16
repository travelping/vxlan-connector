FROM alpine:3.7

RUN apk update && apk add iproute2

# add nslkp for resolving hostname and check IP validity
ADD nslkp /usr/local/sbin/nslkp

ADD run.sh /usr/local/sbin/run.sh

CMD run.sh
