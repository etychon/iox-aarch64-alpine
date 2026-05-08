FROM arm64v8/alpine:3.21 AS runtime

COPY idle.sh /idle.sh
COPY iox-banner.sh /etc/profile.d/iox-banner.sh
RUN chmod 0755 /idle.sh
RUN chmod 0644 /etc/profile.d/iox-banner.sh
RUN apk add --no-cache coreutils eudev picocom bash curl git htop unzip vim wget less net-tools joe curl iproute2 python3 nmap tcpdump lsof busybox-extras minicom screen
  
ARG APP_NAME=iox-aarch64-alpine
ARG APP_VERSION=unknown


ENV HOME=/root \
    TERM=xterm \
    ENV=/etc/profile.d/iox-banner.sh \
    IOX_APP_NAME=${APP_NAME} \
    IOX_APP_VERSION=${APP_VERSION} \
    IOX_APP_AUTHOR="Emmanuel Tychon"
WORKDIR /root
CMD ["sh", "/idle.sh"]

FROM --platform=${BUILDPLATFORM} multiarch/qemu-user-static:x86_64-aarch64 AS qemu
FROM runtime AS runtime-with-qemu
COPY --from=qemu /usr/bin/qemu-aarch64-static /usr/bin/qemu-aarch64-static
