#!/usr/bin/env bash

# Removes Python cache directories recursively in current directory.

set -euo pipefail

find . -type d \( \
    -name "__pycache__" -o \
    -name ".pytest_cache" -o \
    -name ".mypy_cache" \
\) -prune -exec rm -rf {} +

echo "Project cleaned."