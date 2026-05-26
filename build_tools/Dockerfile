FROM ubuntu:24.04

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get -y update && \
    apt-get -y install sudo \
                       python3 \
                       tar \
                       wget \
                       curl \
                       git \
                       git-lfs \
                       build-essential \
                       libglib2.0-0 \
                       pkg-config

ADD . /build_tools
WORKDIR /build_tools

CMD ["sh", "-c", "cd tools/linux && python3 ./automate.py"]