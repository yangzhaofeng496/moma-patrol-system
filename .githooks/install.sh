#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
current=$(git config --local --get core.hooksPath || true)
if [ -n "$current" ] && [ "$current" != '.githooks' ]; then
    echo "已有 core.hooksPath=$current，请先合并现有 hook。" >&2
    exit 1
fi
chmod +x .githooks/post-checkout
git config --local core.hooksPath .githooks
echo '已启用子模块分支切换 hook。首次同步：sh .githooks/post-checkout HEAD HEAD 1'
