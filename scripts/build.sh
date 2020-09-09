#!/usr/bin/env bash
set -e
trap '>&2 printf "\n\e[01;31mError: Command \`%s\` on line $LINENO failed with exit code $?\033[0m\n" "$BASH_COMMAND"' ERR

## find directory above where this script is located following symlinks if neccessary
readonly BASE_DIR="$(
  cd "$(
    dirname "$(
      (readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}") \
        | sed -e "s#^../#$(dirname "$(dirname "${BASH_SOURCE[0]}")")/#"
    )"
  )/.." >/dev/null \
  && pwd
)"
pushd ${BASE_DIR} >/dev/null

PUSH_FLAG=
LATEST_FLAG=

## argument parsing
## parse arguments
while (( "$#" )); do
  case "$1" in
    --push)
      PUSH_FLAG=1
      shift
      ;;
    --latest)
      LATEST_FLAG=1
      shift
      ;;
    *)
      error "Unrecognized argument '$1'"
      exit -1
      ;;
  esac
done

## login to docker hub as needed
if [[ $PUSH_FLAG ]]; then
  [ -t 1 ] && docker login \
    || echo "${DOCKER_PASSWORD:-}" | docker login -u "${DOCKER_USERNAME:-}" --password-stdin
fi

## iterate over and build each version; by default building latest version;
## build matrix will override to build each supported version
PACKER_VERSION="${PACKER_VERSION:-"1.6.2"}"
PACKER_VERSION_SHA256SUM="${PACKER_VERSION_SHA256SUM:-"089fc9885263bb283f20e3e7917f85bb109d9335f24d59c81e6f3a0d4a96a608"}"

IMAGE_NAME="docker.io/davidalger/packer"
export PACKER_VERSION PACKER_VERSION_SHA256SUM

printf "\e[01;31m==> building ${IMAGE_NAME}:${PACKER_VERSION}\033[0m\n"
docker build -t "${IMAGE_NAME}:${PACKER_VERSION}" --build-arg PACKER_VERSION --build-arg PACKER_VERSION_SHA256SUM ${BASE_DIR}

if [[ $PUSH_FLAG ]]; then
  docker push "${IMAGE_NAME}:${PACKER_VERSION}"

  if [[ $LATEST_FLAG ]]; then
    docker tag "${IMAGE_NAME}:${PACKER_VERSION}" "${IMAGE_NAME}:latest"
    docker push "${IMAGE_NAME}:latest"
  fi
fi
