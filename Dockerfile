FROM arm64v8/alpine:3.21 AS runtime

COPY idle.sh /idle.sh
RUN chmod 0755 /idle.sh
RUN apk add --no-cache coreutils eudev picocom bash curl git htop unzip vim wget less net-tools joe curl iproute2 python3 nmap tcpdump lsof busybox-extras minicom screen
  

ENV HOME=/root \
    TERM=xterm
WORKDIR /root
CMD ["sh", "/idle.sh"]

FROM multiarch/qemu-user-static:x86_64-aarch64 AS qemu
FROM runtime AS runtime-with-qemu
COPY --from=qemu /usr/bin/qemu-aarch64-static /usr/bin/qemu-aarch64-static
