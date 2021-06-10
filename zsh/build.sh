#!/bin/bash

# Enter the directory
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1

# Get image username
USERNAME="$1"
# Get image from directory name
IMAGE="$(basename "$(pwd)")"

# List of published zshusers/zsh Docker images
versions="$(wget -qO- https://registry.hub.docker.com/v1/repositories/zshusers/zsh/tags | sed 's/[^0-9.]*"name": "\([^"]*\)"[^0-9.]*/\n\1\n/g;s/^\n//')"

# Build images
for version in $versions; do
    docker buildx build -t "$USERNAME/$IMAGE:$version" --build-arg ZSH_VERSION="$version" .
done

# Tag latest image
latest=$(tr ' ' '\n' <<< "$versions" | sort -V | tail -2 | head -1)
docker tag "$USERNAME/$IMAGE:$latest" "$USERNAME/$IMAGE:latest"
