FROM debian:latest

ARG user=pfu
ARG uid=1000
ARG group=pfu
ARG gid=1000
ARG SSH_PUBLIC_KEY
ARG HTTP_PROXY
ARG HTTPS_PROXY

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8
    # # HTTP_PROXY=${HTTP_PROXY} \
    # # HTTPS_PROXY=${HTTPS_PROXY} \
    # # http_proxy=${HTTP_PROXY} \
    # # https_proxy=${HTTPS_PROXY}

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
    composer php default-jdk-headless tmux xsel xclip gh neofetch net-tools clangd clang-format clang-tidy \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g ${gid} ${group} && \
    useradd --create-home --no-log-init --shell /bin/bash -u ${uid} -g ${gid} ${user} && \
    adduser ${user} sudo && \
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

# RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"  \
#     && git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-/home/${user}/.oh-my-zsh/custom}/themes/powerlevel10k \
#     && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
#     && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
#     && git clone --depth=1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions \
#     && sed -i 's#^ZSH_THEME=.*$#ZSH_THEME="powerlevel10k/powerlevel10k"#' /home/${user}/.zshrc \
#     && sed -i 's#^plugins=.*$#plugins=(git zsh-autosuggestions zsh-completions zsh-syntax-highlighting )#' /home/${user}/.zshrc \
#     && echo "POWERLEVEL9K_DISABLE_GITSTATUS=true" >> /home/${user}/.zshrc \
#     && echo "POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true" >> /home/${user}/.zshrc \
#     && echo "export TERM=xterm-256color" >> /home/${user}/.zshrc

# COPY .p10k.zsh /home/${user}    

EXPOSE 2222

WORKDIR /home/${user}

USER ${user}

CMD ["sh", "-c", "sudo nohup /usr/sbin/sshd -D"]
