#!/bin/sh
printf '\033c\033]0;%s\a' Cross Adventures
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Cross-Adventures-Linux.x86_64" "$@"
