FROM ubuntu

LABEL maintainer "Michael Jungo <michaeljungo92@gmail.com>"

RUN apt-get update && apt-get install -y build-essential git cmake clang
RUN git clone https://github.com/WebAssembly/binaryen && \
      cd binaryen && \
      cmake . && make install
