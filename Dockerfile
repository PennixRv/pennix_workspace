FROM fedorariscv/base:latest

ARG user=pfu
ARG uid=1000
ARG group=pfu
ARG gid=1000
ARG SSH_PUBLIC_KEY
ARG HTTP_PROXY
ARG HTTPS_PROXY

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    http_proxy=${HTTP_PROXY} \
    https_proxy=${HTTPS_PROXY}

RUN dnf -y install dnf-plugins-core && \
    dnf config-manager --set-enabled updates-testing && \
    dnf -y update && \
    dnf -y install glibc-langpack-en openssh-server sudo git python3-distutils gcc g++ make file wget gawk diffstat bzip2 cpio chrpath zstd lz4

RUN localedef -i en_US -f UTF-8 en_US.UTF-8

RUN dnf -y install git rust cargo gcc g++ autoconf automake cmake golang llvm clang clang-tools-extra \
    bear nodejs lua ruby ruby-devel zsh neovim passwd openssl fzf python3-pip wget luarocks \
    composer php java-1.8.0-openjdk-headless tmux xsel xclip gh neofetch net-tools clang clang-tools-extra clang-format clang-tidy \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf && \
    dnf clean all

RUN groupadd -g ${gid} ${group} && \
    useradd --create-home --no-log-init --shell /bin/bash -u ${uid} -g ${gid} ${user} && \
    usermod -aG wheel ${user} && \
    echo "${user}:${user}" | chpasswd && \
    echo "${user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${user} && \
    chmod 440 /etc/sudoers.d/${user} && \
    chown -R ${user}:${group} /home/${user}

RUN mkdir /var/run/sshd && \
    sed -i 's/^#\(PermitRootLogin\) .*/\1 yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\(PasswordAuthentication\) .*/\1 yes/' /etc/ssh/sshd_config && \
    sed -i 's/^\(UsePAM yes\)/# \1/' /etc/ssh/sshd_config && \
    sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config && \
    rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*.pub && \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' -q && \
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' -q && \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' -q

RUN mkdir -p /home/${user}/.ssh && \
    echo "${SSH_PUBLIC_KEY}" > /home/${user}/.ssh/authorized_keys && \
    chown -R ${user}:${group} /home/${user}/.ssh && \
    chmod 600 /home/${user}/.ssh/authorized_keys

EXPOSE 2222

WORKDIR /home/${user}

USER ${user}

CMD ["sh", "-c", "sudo nohup /usr/sbin/sshd -D"]
