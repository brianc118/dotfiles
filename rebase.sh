#!/bin/bash

set -euo pipefail

# Function to display usage
usage() {
    echo "Usage: $0 -s <source_commit> -d <destination_commit>"
    echo "  -s: Source commit (usually the older commit)"
    echo "  -d: Destination commit (usually the newer commit to rebase onto)"
    exit 1
}

# Parse command line arguments
while getopts "s:d:" opt; do
    case $opt in
        s) source_commit="$OPTARG" ;;
        d) destination_commit="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if both arguments are provided
if [ -z "$source_commit" ] || [ -z "$destination_commit" ]; then
    usage
fi

# Validate commits
if ! git rev-parse --verify "$source_commit" >/dev/null 2>&1; then
    echo "Error: Invalid source commit" >&2
    exit 1
fi

if ! git rev-parse --verify "$destination_commit" >/dev/null 2>&1; then
    echo "Error: Invalid destination commit" >&2
    exit 1
fi

echo "Source commit: $source_commit"
echo "Destination commit: $destination_commit"

# Initialize an empty array to store leaf branches
leaf_branches=()

while read branch; do
    if [ -z "$(git branch --contains $branch | grep -v "$branch")" ]; then
        leaf_branches+=("$branch")
    fi
done < <(git branch --format="%(refname:short)" --contains $source_commit | grep -v "^(HEAD")

echo "Leaf branches based on source commit:"
printf '  %s\n' "${leaf_branches[@]}"

# Perform rebase for each leaf branch
for branch in "${leaf_branches[@]}"; do
    echo "Rebasing branch: $branch"
    echo "git rebase $destination_commit $branch --update-refs"
    if git rebase $destination_commit $branch --update-refs; then
        echo "Rebased $branch"
    else
        echo "Failed to rebase $branch"
        git rebase --abort
    fi
done

