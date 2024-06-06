#!/bin/bash

# 容器名称
DEFAULT_CONTAINER_NAME="pennix_debian_workspace"
CONTAINER_NAME=$DEFAULT_CONTAINER_NAME

# 初始化参数
FORCE=false
PROXY_URL=""

# 显示帮助信息
# 显示帮助信息
show_help() {
    echo "Usage: ./build_container.sh [options]"
    echo ""
    echo "Options:"
    echo "  -f, --force          Force remove existing container and rebuild"
    echo "  -p, --proxy-url      Proxy URL to use"
    echo "  -n, --name           Container name (default: $DEFAULT_CONTAINER_NAME)"
    echo "  -h, --help           Display this help message"
}

# 检查 Docker 服务状态
check_docker_service() {
    if (! systemctl is-active --quiet docker); then
        echo "Docker service is not running. Please start Docker and try again."
        exit 1
    fi
}

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--force) FORCE=true ;;
        -p|--proxy-url) PROXY_URL="$2"; shift ;;
        -n|--name) CONTAINER_NAME="$2"; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# 如果未指定 --proxy-url，则尝试从环境变量中获取代理配置
if [[ -z "$PROXY_URL" ]]; then
    PROXY_URL=${HTTP_PROXY:-${http_proxy:-${HTTPS_PROXY:-${https_proxy}}}}
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
    if [[ -n "$PROXY_URL" ]]; then
        export HTTP_PROXY=$PROXY_URL
        export HTTPS_PROXY=$PROXY_URL
        export http_proxy=$PROXY_URL
        export https_proxy=$PROXY_URL
    fi
    docker-compose build
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
