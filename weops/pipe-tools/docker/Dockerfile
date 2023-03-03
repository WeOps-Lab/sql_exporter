#
# build container
#
FROM --platform=linux/amd64 golang:1.19-alpine as builder
WORKDIR /

COPY sql_exporter /sql_exporter

EXPOSE     9121
ENTRYPOINT [ "/sql_exporter" ]
