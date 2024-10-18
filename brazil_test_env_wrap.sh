#!/usr/bin/env bash

set -eux

cd "$BRAZIL_PACKAGE_DIR"
brazil-test-exec "$INNER_CMD" "$@"

