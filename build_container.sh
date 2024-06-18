#!/bin/bash

# Default container name
DEFAULT_CONTAINER_NAME="pennix_debian_workspace"
CONTAINER_NAME=$DEFAULT_CONTAINER_NAME

# Initialize parameters
FORCE=false
PROXY_URL=""

# Display help message
show_help() {
    echo "Usage: ./build_container.sh [options]"
    echo ""
    echo "Options:"
    echo "  -f, --force          Force remove existing container and rebuild"
    echo "  -p, --proxy-url      Proxy URL to use"
    echo "  -n, --name           Container name (default: $DEFAULT_CONTAINER_NAME)"
    echo "  -h, --help           Display this help message"
}

# Check Docker service status
check_docker_service() {
    if (! systemctl is-active --quiet docker); then
        echo "Docker service is not running. Please start Docker and try again."
        exit 1
    fi
}

# Update proxy settings in ~/.docker/config.json
update_docker_config() {
    CONFIG_FILE="$HOME/.docker/config.json"
    mkdir -p "$(dirname "$CONFIG_FILE")"

    if [[ -f "$CONFIG_FILE" ]]; then
        # Read existing configuration
        CONFIG=$(jq '.' "$CONFIG_FILE")
    else
        # Create empty configuration
        CONFIG='{}'
    fi

    # Update proxy settings
    if [[ -n "$PROXY_URL" ]]; then
        UPDATED_CONFIG=$(echo "$CONFIG" | jq --arg http_proxy "$PROXY_URL" --arg https_proxy "$PROXY_URL" '
            .proxies.default.httpProxy = $http_proxy |
            .proxies.default.httpsProxy = $https_proxy'
        )

        # Save updated configuration
        echo "$UPDATED_CONFIG" > "$CONFIG_FILE"
    fi
}

# Parse command line arguments
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

# If --proxy-url is not specified, try to get proxy configuration from environment variables
if [[ -z "$PROXY_URL" ]]; then
    PROXY_URL=${HTTP_PROXY:-${http_proxy:-${HTTPS_PROXY:-${https_proxy}}}}
fi

# Check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"
}

# Remove container
remove_container() {
    echo "Removing existing container..."
    docker rm -f ${CONTAINER_NAME}
}

# Build and run container
build_and_run_container() {
    echo "Building and running container..."
    if [[ -n "$PROXY_URL" ]]; then
        export HTTP_PROXY=$PROXY_URL
        export HTTPS_PROXY=$PROXY_URL
        export http_proxy=$PROXY_URL
        export https_proxy=$PROXY_URL
        update_docker_config
    fi
    docker-compose build
    docker-compose up -d
}

# Main logic
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
