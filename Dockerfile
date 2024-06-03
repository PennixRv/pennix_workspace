FROM debian:latest

ARG user=pfu
ARG uid=1000
ARG group=pfu
ARG gid=1000

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# 更新apt源并安装依赖
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware\n\
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware\n\
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware\n\
deb http://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/* && \
    apt-get update && \
    apt-get install -y --no-install-recommends apt-utils locales openssh-server sudo git python3-distutils gcc g++ make file wget gawk diffstat bzip2 cpio chrpath zstd lz4

# 配置本地化设置
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# 安装开发工具和其他依赖
RUN apt-get update && \
    apt-get install -y git rustc cargo gcc g++ autoconf automake cmake golang llvm clang-tools \
    clang bear nodejs lua5.3 ruby ruby-dev zsh neovim passwd openssl fzf python3-pip wget luarocks \
    composer php default-jdk-headless tmux xsel xclip gh neofetch \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 创建用户并设置权限
RUN groupadd -g ${gid} ${group} && \
    useradd --create-home --no-log-init --shell /bin/bash -u ${uid} -g ${gid} ${user} && \
    adduser ${user} sudo && \
    echo "${user}:${user}" | chpasswd && \
    chown -R ${user}:${group} /home/${user}

RUN mkdir /var/run/sshd \
    && sed -i 's/^#\(PermitRootLogin\) .*/\1 yes/' /etc/ssh/sshd_config \
    && sed -i 's/^\(UsePAM yes\)/# \1/' /etc/ssh/sshd_config

EXPOSE 22

WORKDIR /home/${user}

USER ${user}