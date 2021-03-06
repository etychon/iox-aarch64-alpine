FROM multiarch/qemu-user-static:x86_64-aarch64 as qemu
FROM arm64v8/alpine:latest
COPY --from=qemu /usr/bin/qemu-aarch64-static /usr/bin

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm

ADD idle.sh /idle.sh

# Install.
RUN \
  apk add  --no-cache bash curl git htop unzip vim wget less net-tools joe curl iproute2 python3 nmap tcpdump lsof busybox-extras minicom screen
  
# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash", "/idle.sh"]
