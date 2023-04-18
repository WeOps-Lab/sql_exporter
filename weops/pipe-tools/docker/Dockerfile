#
# build container
#
FROM --platform=linux/amd64 golang:1.19-alpine as builder
WORKDIR /
ADD . /

COPY sql_exporter /sql_exporter
RUN chmod +x /sql_exporter

EXPOSE     9399
ENTRYPOINT [ "/sql_exporter" ]
