#!/bin/bash

VERSION="${TRAVIS_TAG:-0.0.0}"
VERSION="${VERSION#v}"
: "${DOCKER_TAG:=sumologic/fluent-bit}"
: "${DOCKER_USERNAME:=sumodocker}"
DOCKER_TAGS="https://registry.hub.docker.com/v1/repositories/sumologic/fluent-bit/tags"

echo "Starting build process in: $(pwd) with version tag: ${VERSION}"
err_report() {
    echo "Script error on line $1"
    exit 1
}
trap 'err_report $LINENO' ERR

echo "Building docker image with $DOCKER_TAG:local in $(pwd)..."
docker build . -f ./Dockerfile -t $DOCKER_TAG:local --no-cache

function push_docker_image() {
  local version="$1"

  echo "Tagging docker image $DOCKER_TAG:local with $DOCKER_TAG:$version..."
  docker tag $DOCKER_TAG:local $DOCKER_TAG:$version
  echo "Pushing docker image $DOCKER_TAG:$version..."
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  docker push $DOCKER_TAG:$version
}

if [ -n "$DOCKER_PASSWORD" ] && [ -n "$TRAVIS_TAG" ]; then
  push_docker_image "$VERSION"
  push_helm_chart "$VERSION"

elif [ -n "$DOCKER_PASSWORD" ] && [ "$TRAVIS_BRANCH" == "sumologic-v1.3.11" ] && [ "$TRAVIS_EVENT_TYPE" == "push" ]; then
  dev_build_tag=$(git describe --tags --always)
  dev_build_tag=${dev_build_tag#v}
  push_docker_image "$dev_build_tag"

else
  echo "Skip Docker pushing"
fi

echo "DONE"
