#!/bin/bash

# Enter the directory
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1

# Get image username
USERNAME="$1"
# Get image from directory name
IMAGE="$(basename "$(pwd)")"

# $zsh_tags is an environment variable passed via secrets

# Build images
for version in $zsh_tags; do
    docker buildx build -t "$USERNAME/$IMAGE:$version" --build-arg ZSH_VERSION="$version" .
done

# Tag latest image
latest=$(tr ' ' '\n' <<< "$zsh_tags" | sed '/^$/d' | sort -V | tail -2 | head -1)
docker tag "$USERNAME/$IMAGE:$latest" "$USERNAME/$IMAGE:latest"
