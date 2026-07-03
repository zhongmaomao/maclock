#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
swift run MacLock
