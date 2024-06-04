FROM debian:latest

ARG user=pfu
ARG uid=1000
ARG group=pfu
ARG gid=1000
ARG SSH_PUBLIC_KEY

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware\n\
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware\n\
deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware\n\
deb http://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/* && \
    apt-get update && \
    apt-get install -y --no-install-recommends apt-utils locales openssh-server sudo git python3-distutils gcc g++ make file wget gawk diffstat bzip2 cpio chrpath zstd lz4

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

RUN apt-get update && \
    apt-get install -y git rustc cargo gcc g++ autoconf automake cmake golang llvm clang-tools \
    clang bear nodejs lua5.3 ruby ruby-dev zsh neovim passwd openssl fzf python3-pip wget luarocks \
    composer php default-jdk-headless tmux xsel xclip gh neofetch net-tools \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g ${gid} ${group} && \
    useradd --create-home --no-log-init --shell /bin/bash -u ${uid} -g ${gid} ${user} && \
    adduser ${user} sudo && \
    echo "${user}:${user}" | chpasswd && \
    echo "${user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${user} && \
    chmod 440 /etc/sudoers.d/${user} && \
    chown -R ${user}:${group} /home/${user}

RUN mkdir /var/run/sshd \
    && sed -i 's/^#\(PermitRootLogin\) .*/\1 yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\(PasswordAuthentication\) .*/\1 yes/' /etc/ssh/sshd_config \
    && sed -i 's/^\(UsePAM yes\)/# \1/' /etc/ssh/sshd_config \
    && sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config \
    && rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*.pub \
    && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' -q \
    && ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' -q \
    && ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' -q

RUN mkdir -p /home/${user}/.ssh && \
    echo "${SSH_PUBLIC_KEY}" > /home/${user}/.ssh/authorized_keys && \
    chown -R ${user}:${group} /home/${user}/.ssh && \
    chmod 600 /home/${user}/.ssh/authorized_keys

EXPOSE 2222

WORKDIR /home/${user}

USER ${user}

CMD ["sh", "-c", "sudo nohup /usr/sbin/sshd -D && tail -f /dev/null"]