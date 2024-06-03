FROM debian:latest

ARG user=pfu
ARG uid=1000
ARG group=pfu
ARG gid=1000

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware\n\
deb-src http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware\n\
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware\n\
deb-src http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware\n\
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware\n\
deb-src http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware\n\
deb http://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware\n\
deb-src http://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/* && \
    apt-get update && \
    apt-get install -y apt-utils locales && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    apt-get install -y openssh-server && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    apt-get install -y sudo git python3-distutils gcc g++ make file wget gawk diffstat bzip2 cpio chrpath zstd lz4 bzip2 && \
    groupadd -g ${gid} ${group} && \
    useradd --create-home --no-log-init --shell /bin/bash -u ${uid} -g ${gid} ${user} && \
    adduser ${user} sudo && \
    echo "${user}:1" | chpasswd && \
    chown -R ${user}:${group} /home/${user} && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/${user}

USER ${user}