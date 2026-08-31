#!/bin/sh
# 跑 · 盘古机的运行脚本
#
# Go 装在隔离目录中，未并入系统 PATH，故先设 GOROOT / GOPATH / GOCACHE，
# 再转交 go 本身。用法：
#
#   ./跑.sh test ./...        跑全部测试
#   ./跑.sh run ./cmd/pangu   跑命令行演示
#   ./跑.sh vet ./...         静态检查
#   ./跑.sh fmt .             格式化
#
# 详见 典/02-实现约束.md 第五条。

set -e

export GOROOT="${HOME}/.workbuddy/binaries/go/go"
export GOPATH="${HOME}/.workbuddy/binaries/go/gopath"
export GOCACHE="${HOME}/.workbuddy/binaries/go/gocache"
export PATH="${GOROOT}/bin:${PATH}"

cd "$(dirname "$0")" || exit 1

exec go "$@"
