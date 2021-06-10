#!/bin/bash

# Enter the directory
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1

# Get image username
USERNAME="$1"
# Get image from directory name
IMAGE="$(basename "$(pwd)")"

# Get ohmyzsh stable releases
versions="$(curl -sL https://api.github.com/repos/ohmyzsh/ohmyzsh/tags | sed -n 's/[^0-9.]*"name": "v\?\([^"]*\)"[^0-9.]*/\n\1/g;s/^\n//p')"
versions="$versions master"

# Build images
for version in $versions; do
    docker buildx build -t "$USERNAME/$IMAGE:$version" --build-arg OMZ_VERSION="$version" .
done

# Tag latest image
latest=$(tr ' ' '\n' <<< "$versions" | sort -V | tail -2 | head -1)
docker tag "$USERNAME/$IMAGE:$latest" "$USERNAME/$IMAGE:latest"
