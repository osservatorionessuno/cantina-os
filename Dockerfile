
FROM golang:trixie

RUN apt-get -qq update
RUN apt-get install -qqy ca-certificates make cpio mmdebstrap libsystemd-shared pigz fakechroot fakeroot

RUN go install system-transparency.org/stmgr@latest
RUN go install system-transparency.org/stboot@latest

WORKDIR /stimages
