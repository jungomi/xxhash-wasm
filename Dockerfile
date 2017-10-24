FROM ubuntu

LABEL maintainer "Michael Jungo <michaeljungo92@gmail.com>"

RUN apt-get update && apt-get install -y build-essential git cmake clang
RUN git clone --recursive https://github.com/WebAssembly/wabt && \
      cd wabt && \
      make install-clang-release 
