
FROM golang:bookworm

RUN apt-get -qq update
RUN apt-get install -qqy ca-certificates make cpio mmdebstrap libsystemd-shared pigz

RUN go install system-transparency.org/stmgr@latest
RUN go install system-transparency.org/stboot@latest

# COPY stimages /stimages

WORKDIR /stimages
