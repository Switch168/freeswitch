FROM debian:bullseye-slim

COPY ./files/* /tmp/

RUN for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done \
    && apt-get update && apt-get -y --quiet --allow-remove-essential upgrade \
    && apt-get install -y --quiet --no-install-recommends \
    python-is-python3 lsof gcc g++ make cmake build-essential git autoconf automake default-mysql-client redis-tools \
    curl telnet libtool libtool-bin libssl-dev libcurl4-openssl-dev libz-dev liblz4-tool \
    libxtables-dev libip6tc-dev libip4tc-dev  libiptc-dev libavformat-dev liblua5.1-0-dev libavfilter-dev libavcodec-dev libswresample-dev \
    libevent-dev libpcap-dev libxmlrpc-core-c3-dev markdown libjson-glib-dev lsb-release libpq-dev php-dev \
    libhiredis-dev gperf libspandsp-dev default-libmysqlclient-dev htop dnsutils gdb libtcmalloc-minimal4 \
    gnupg2 wget pkg-config ca-certificates libjpeg-dev libsqlite3-dev libpcre3-dev libldns-dev \
    libspeex-dev libspeexdsp-dev libedit-dev libtiff-dev yasm libswscale-dev haveged libre2-dev \
    libopus-dev libsndfile-dev libshout3-dev libmpg123-dev libmp3lame-dev libopusfile-dev libgoogle-perftools-dev \
    && export LD_LIBRARY_PATH=/usr/local/lib:/usr/lib \
    && cd /tmp \
    && tar xvfz SpeechSDK-Linux-1.34.0.tar.gz \
    && cd SpeechSDK-Linux-1.34.0 \
    && ls -lrt /usr/local/lib/ \
    && cd /usr/local/src \
    && git config --global http.postBuffer 524288000  \
    && git config --global https.postBuffer 524288000 \
    && git config --global pull.rebase true \
    && git clone https://github.com/signalwire/freeswitch.git -b v1.10.10 \
    && git clone https://github.com/warmcat/libwebsockets.git -b v4.3.2 \
    && git clone https://github.com/switch168/freeswitch_modules.git freeswitch-modules \
    && git clone https://github.com/grpc/grpc -b master && cd grpc && git checkout v1.57.0 && cd .. \
    && cd freeswitch/libs \
    && git clone https://github.com/freeswitch/spandsp.git && cd spandsp && git checkout 0d2e6ac && cd .. \
    && git clone https://github.com/freeswitch/sofia-sip.git -b master \
    && git clone https://github.com/dpirch/libfvad.git \
    && git clone https://github.com/googleapis/googleapis -b master \
    && cd googleapis && git checkout 29374574304f3356e64423acc9ad059fe43f09b5 && cd .. \
    && cp -r /usr/local/src/freeswitch-modules/modules/mod_audio_fork /usr/local/src/freeswitch/src/mod/applications/mod_audio_fork \
    && cp -r /usr/local/src/freeswitch-modules/modules/mod_google_transcribe /usr/local/src/freeswitch/src/mod/applications/mod_google_transcribe \
    && cp -r /usr/local/src/freeswitch-modules/modules/mod_dialogflow /usr/local/src/freeswitch/src/mod/applications/mod_dialogflow \
    && cp /tmp/configure.ac.extra /usr/local/src/freeswitch/configure.ac \
    && cp /tmp/Makefile.am.extra /usr/local/src/freeswitch/Makefile.am \
    && cp /tmp/modules.conf.in.extra /usr/local/src/freeswitch/build/modules.conf.in \
    && cp /tmp/modules.conf.vanilla.xml.extra /usr/local/src/freeswitch/conf/vanilla/autoload_configs/modules.conf.xml \
    && cp /tmp/avmd.conf.xml /usr/local/src/freeswitch/conf/vanilla/autoload_configs/avmd_conf.xml \
    && cp /tmp/switch_rtp.c.patch /usr/local/src/freeswitch/src \
    && cp /tmp/switch_core_media.c.patch /usr/local/src/freeswitch/src \
    && cp /tmp/mod_avmd.c.patch /usr/local/src/freeswitch/src/mod/applications/mod_avmd \
    && cp /tmp/mod_httapi.c.patch /usr/local/src/freeswitch/src/mod/applications/mod_httapi \
    && cd /usr/local/src/freeswitch/src \
    && patch < switch_rtp.c.patch \
    && patch < switch_core_media.c.patch \
    && cd /usr/local/src/freeswitch/src/mod/applications/mod_avmd \
    && patch < mod_avmd.c.patch \
    && cd /usr/local/src/freeswitch/src/mod/applications/mod_httapi \
    && patch < mod_httapi.c.patch \
    && cd /usr/local/src/freeswitch/src \
    && cp /tmp/switch_event.c . \
    && cd /usr/local/src/libwebsockets \
    && mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo && make && make install \
    && cd /usr/local/src/freeswitch/libs/libfvad \
    && autoreconf -i && ./configure && make && make install \
    && cd /usr/local/src/freeswitch/libs/spandsp \
    && ./bootstrap.sh && ./configure && make && make install \
    && cd /usr/local/src/freeswitch/libs/sofia-sip \
    && ./bootstrap.sh && ./configure && make && make install \
    && echo building grpc \
    && cd /usr/local/src/grpc \
    && git submodule update --init --recursive \
    && mkdir -p cmake/build \
    && cd cmake/build \
    && cmake -DBUILD_SHARED_LIBS=ON -DgRPC_SSL_PROVIDER=package -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo ../.. \
    && make \
    && make install \
    && cd /usr/local/src/freeswitch \
    && ./bootstrap.sh -j \
    && ./configure --enable-tcmalloc=yes --with-extra=yes \
    && make \
    && make install \
    && make cd-sounds-install cd-moh-install \
    && cp /tmp/acl.conf.xml /usr/local/freeswitch/conf/autoload_configs \
    && cp /tmp/event_socket.conf.xml /usr/local/freeswitch/conf/autoload_configs \
    && cp /tmp/switch.conf.xml /usr/local/freeswitch/conf/autoload_configs \
    && cp /tmp/conference.conf.xml /usr/local/freeswitch/conf/autoload_configs \
    && rm -Rf /usr/local/freeswitch/conf/dialplan/* \
    && rm -Rf /usr/local/freeswitch/conf/sip_profiles/* \
    && cp /usr/local/src/freeswitch/conf/vanilla/autoload_configs/modules.conf.xml /usr/local/freeswitch/conf/autoload_configs \
    && sed -i -e 's/global_codec_prefs=OPUS,G722,PCMU,PCMA,H264,VP8/global_codec_prefs=PCMU,PCMA,OPUS,G722/g' /usr/local/freeswitch/conf/vars.xml \
    && sed -i -e 's/outbound_codec_prefs=OPUS,G722,PCMU,PCMA,H264,VP8/outbound_codec_prefs=PCMU,PCMA,OPUS,G722/g' /usr/local/freeswitch/conf/vars.xml \

    ONBUILD ADD dialplan /usr/local/freeswitch/conf/dialplan
ONBUILD ADD sip_profiles /usr/local/freeswitch/conf/sip_profiles
