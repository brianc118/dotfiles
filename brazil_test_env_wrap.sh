#!/usr/bin/env bash

set -eux

WORKSPACE_DIR="$(dirname "$(dirname "$BRAZIL_PACKAGE_DIR")")"
CMD_MATCHES=("$WORKSPACE_DIR"/env/*/test-runtime/bin/"$INNER_CMD")

if [ ${#CMD_MATCHES[@]} -eq 1 ]; then
  # if exactly one match we optimize and directly use the binary
  # without brazil-test-exec
  "${CMD_MATCHES[0]}" "$@"
else
  cd "$BRAZIL_PACKAGE_DIR"
  brazil-test-exec "$INNER_CMD" "$@"
fi


