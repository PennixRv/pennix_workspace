#!/bin/bash

# 容器名称
CONTAINER_NAME="pennix_debian_workspace"

# 显示帮助信息
show_help() {
    echo "Usage: ./run_container.sh [options]"
    echo ""
    echo "Options:"
    echo "  -f, --force            Force remove existing container and rebuild"
    echo "  -k, --key <public_key> Specify the SSH public key to use"
    echo "  -h, --help             Display this help message"
}

# 检查 Docker 服务状态
check_docker_service() {
    if (! systemctl is-active --quiet docker); then
        echo "Docker service is not running. Please start Docker and try again."
        exit 1
    fi
}

# 解析命令行参数
FORCE=false
SSH_PUBLIC_KEY=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--force) FORCE=true ;;
        -k|--key) SSH_PUBLIC_KEY="$2"; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# 如果未提供 SSH_PUBLIC_KEY 参数，则从 .env 文件中加载
if [ -z "$SSH_PUBLIC_KEY" ]; then
    if [ -f .env ]; then
        source .env
        SSH_PUBLIC_KEY=${SSH_PUBLIC_KEY:-$(cat ~/.ssh/id_rsa.pub)}
    else
        SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)
    fi
fi

# 检查容器是否存在
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"
}

# 删除容器
remove_container() {
    echo "Removing existing container..."
    docker rm -f ${CONTAINER_NAME}
}

# 构建并运行容器
build_and_run_container() {
    echo "Building and running container..."
    docker-compose build --build-arg SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY"
    docker-compose up -d
}

# 主逻辑
check_docker_service

if container_exists; then
    if $FORCE; then
        remove_container
        build_and_run_container
    else
        echo "Container ${CONTAINER_NAME} already exists. Use '-f' or '--force' parameter to rebuild."
    fi
else
    build_and_run_container
fi