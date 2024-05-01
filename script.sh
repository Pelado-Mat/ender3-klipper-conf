#!/usr/bin/env bash

# abort if its printing

STATE=$(curl -X GET http://127.0.0.1:7125/printer/objects/query?print_stats 2>/dev/null | grep -oP '(?<="state": ")[^"]*')
if [ "$STATE" = "printing" ]; then
  echo "Abortamos: se esta imprimiendo"
  exit 0
fi

# Set parent directory path
parent_path=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)

# Initialize variables from .env file
github_token=$(grep 'github_token=' "$parent_path"/.env | sed 's/^.*=//')
github_username=$(grep 'github_username=' "$parent_path"/.env | sed 's/^.*=//')
github_repository=$(grep 'github_repository=' "$parent_path"/.env | sed 's/^.*=//')
backup_folder=$(grep 'backup_folder=' "$parent_path"/.env | sed 's/^.*=//')

# Change directory to parent path
cd "$parent_path" || exit

# Check if backup folder exists, create one if it does not
if [ ! -d "$parent_path/$backup_folder" ]; then
  mkdir "$parent_path/$backup_folder"
fi

# Copy important files into backup folder
while read -r path; do
  file=$(basename "$path")
  cp -r "$path" "$parent_path/$backup_folder"
done < <(grep 'path_' "$parent_path"/.env | sed 's/^.*=//')

# Git commands
git init
git filter-branch --force --index-filter \
  'git rm -r --cached --ignore-unmatch "$parent_path"/.env' \
  --prune-empty --tag-name-filter cat -- --all
#git rm -rf --cached "$parent_path"/.env
git add "$parent_path"
git commit -m "New backup from $(date +"%d-%m-%y")"
git push https://"$github_token"@github.com/"$github_username"/"$github_repository".git
