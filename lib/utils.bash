#!/bin/bash

set -eo pipefail

GITHUB_REPO="https://github.com/grain-lang/grain"

cmd="curl -s"
if [ -n "$GITHUB_API_TOKEN" ]; then
 cmd="$cmd -H 'Authorization: token $GITHUB_API_TOKEN'"
fi

# stolen from https://github.com/rbenv/ruby-build/pull/631/files#diff-fdcfb8a18714b33b07529b7d02b54f1dR942
function sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

function list_github_tags() {
  git ls-remote --tags --refs "$GITHUB_REPO" |
    grep -o 'refs/tags/grain-v.*' | cut -d/ -f3- |
    sed 's/^grain-v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

function get_platform() {
  case "$OSTYPE" in
    darwin*) echo -n "mac" ;;
    linux*) echo -n "linux" ;;
    *) fail "Unsupported platform" ;;
  esac
}

function get_arch() {
  case "$(uname -m)" in
    x86_64) echo -n "x64" ;;
    *) fail "Unsupported architecture" ;;
  esac
}

function get_bin_url() {
  local version=$1
  local platform=$2
  local arch=$3

  local url="$GITHUB_REPO/releases/download/grain-v$version/grain-$platform-$arch"

  echo -n "$url"
}

function get_source_url() {
  local version=$1

  echo -n "$GITHUB_REPO/archive/grain-v$version.zip"
}

function get_temp_dir() {
  local tmpdir
  tmpdir=$(mktemp -d asdf-grain.XXXX)

  echo -n "$tmpdir"
}

function fail() {
  echo -e "\e[31mFail:\e[m $*" 1>&2
  exit 1
}
