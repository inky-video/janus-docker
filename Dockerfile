FROM ubuntu:22.04

COPY ./sources.list /etc/apt/sources.list

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
        libmicrohttpd-dev libjansson-dev \
        libssl-dev libsofia-sip-ua-dev libglib2.0-dev \
        libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev \
        libconfig-dev pkg-config libtool automake \
        git meson \
        ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
    wget make cmake gcc g++ \
    libavcodec-dev libavformat-dev libavfilter-dev libavdevice-dev libavutil-dev libswscale-dev libswresample-dev libpostproc-dev \
    ffmpeg \
	&& rm -rf /var/lib/apt/lists/*
    
WORKDIR /opt
# install libnice
RUN git clone https://gitlab.freedesktop.org/libnice/libnice \
    && cd libnice \
    && meson --prefix=/usr --libdir=lib build \
    && ninja -C build \
    && ninja -C build install

# install libsrtp
RUN wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz \
    && tar xfv v2.2.0.tar.gz \
    && cd libsrtp-2.2.0 \
    && ./configure --prefix=/usr --enable-openssl \
    && make shared_library && make install

RUN git clone https://libwebsockets.org/repo/libwebsockets \
    && cd libwebsockets \
    && mkdir build \
    && cd build \
    && cmake -DLWS_MAX_SMP=1 -DLWS_WITHOUT_EXTENSIONS=0 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. \
    && make && make install

WORKDIR /code
RUN git clone https://github.com/meetecho/janus-gateway.git \
    && cd janus-gateway \
    && sh autogen.sh \
    && ./configure --prefix=/opt/janus --enable-post-processing \
    && make && make install

CMD ["/opt/janus/bin/janus"]