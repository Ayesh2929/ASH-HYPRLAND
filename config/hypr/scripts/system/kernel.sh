#!/bin/bash
set -euo pipefail

case "${1:-}" in
    version) uname -r ;;
    release) uname -v ;;
    arch) uname -m ;;
    hostname) hostname ;;
    *) echo "Usage: kernel.sh [version|release|arch|hostname]"; exit 1 ;;
esac