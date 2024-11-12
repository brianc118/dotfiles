#!/bin/bash

set -eo pipefail

# Function to display usage
usage() {
    echo "Usage: $0 -s <source_commit> -d <destination_commit>"
    echo "  -s: Source commit (usually the older commit, can be branch name, tag, or relative reference)"
    echo "  -d: Destination commit (usually the newer commit to rebase onto, can be branch name, tag, or relative reference)"
    exit 1
}

# Parse command line arguments
while getopts ":s:d:" opt; do
    case $opt in
        s) source_commit="$OPTARG" ;;
        d) destination_commit="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

# Check if both -s and -d options are provided
if [ -z "${source_commit:-}" ] || [ -z "${destination_commit:-}" ]; then
    echo "Error: Both -s and -d options are required." >&2
    usage
fi

# Function to resolve Git references
resolve_ref() {
    git rev-parse --verify "$1^{commit}" 2>/dev/null || {
        echo "Error: Invalid Git reference: $1" >&2
        exit 1
    }
}

# Resolve and validate commits
current_sha=$(resolve_ref "HEAD")
source_sha=$(resolve_ref "$source_commit")
destination_sha=$(resolve_ref "$destination_commit")

echo "Source commit: $source_commit ($source_sha)"
echo "Destination commit: $destination_commit ($destination_sha)"

# Initialize an empty array to store leaf branches
leaf_branches=()

while read branch; do
    if [ -z "$(git branch --contains $branch | grep -v "$branch")" ]; then
        leaf_branches+=("$branch")
    fi
done < <(git branch --format="%(refname:short)" --contains $source_sha | grep -v "^(HEAD")

echo "Leaf branches based on source commit:"
printf '  %s\n' "${leaf_branches[@]}"

# Perform rebase for each leaf branch
for branch in "${leaf_branches[@]}"; do
    echo "Rebasing branch: $branch"
    if git rebase $destination_commit $branch --update-refs; then
        echo "Rebased $branch"
    else
        echo "Failed to rebase $branch"
        git rebase --abort
    fi
done

# Return to the original position
git checkout $current_sha
