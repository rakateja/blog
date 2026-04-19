#!/usr/bin/env bash

#------------------------------------------------------------------------------
# @file
# Builds the Hugo site for Cloudflare Pages deployment.
#------------------------------------------------------------------------------

main() {

  HUGO_VERSION=0.147.0

  export TZ=Asia/Jakarta

  # Install Hugo
  echo "Installing Hugo ${HUGO_VERSION}..."
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  if [ "${ARCH}" = "x86_64" ]; then ARCH="amd64"; elif [ "${ARCH}" = "aarch64" ] || [ "${ARCH}" = "arm64" ]; then ARCH="arm64"; fi
  if [ "${OS}" = "darwin" ]; then
    HUGO_ARCHIVE="hugo_extended_${HUGO_VERSION}_darwin-universal.tar.gz"
  else
    HUGO_ARCHIVE="hugo_extended_${HUGO_VERSION}_linux-${ARCH}.tar.gz"
  fi
  curl -sLJO "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_ARCHIVE}"
  mkdir -p "${HOME}/.local/bin"
  tar -C "${HOME}/.local/bin" -xf "${HUGO_ARCHIVE}" hugo
  rm "${HUGO_ARCHIVE}"
  export PATH="${HOME}/.local/bin:${PATH}"

  echo "Hugo version: $(hugo version)"

  # Initialize theme submodule
  echo "Initializing submodules..."
  git submodule update --init themes/whiteplain

  # Build the site
  echo "Building the site..."
  hugo --gc --minify -t whiteplain

}

set -euo pipefail
main "$@"
