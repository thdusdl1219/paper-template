#!/bin/bash

set -Eeuo pipefail

git_root="$(git rev-parse --show-toplevel)"
tmp_dir="$(mktemp --directory --tmpdir=/tmp "latex_diff.XXXXXXXX")"
rel_path="$(realpath --relative-to="$git_root" "$(pwd)")"

mkdir --parents "$tmp_dir"

old_repo="$tmp_dir/old"

git clone "$git_root" "$old_repo"

cd "$old_repo" || exit
git checkout -q "$2"

new_dir="$git_root/$rel_path"
old_dir="$old_repo/$rel_path"

cd "$old_dir" || exit
make
latexdiff --flatten "$1.tex" "$new_dir/$1.tex" > diff.tex

make TARGET=diff
cp --force diff.pdf "$new_dir/diff.pdf"
