#!/bin/bash

# Execute bash script from the repo root
cd $(dirname "$0")
cd ..

branch_name=automated-bump-engine-schema

if [ -z "$GH_TOKEN" ]; then
  echo "Missing GH_TOKEN variable."
  exit 1
fi

# Function for checking out master and discarding all local changes
function reset_to_master() {
  git checkout master
  git reset --hard origin/master
  git pull
}

reset_to_master
existing_branch=$(git branch -r | grep -i "$branch_name")

if [ ! -z "$existing_branch" ]; then
  echo "There is already a bump branch, please remove/merge it and run this tool again."
  exit 1
fi

# Generate enigma-go based on latest published Qlik Associative Engine image
. ./schema/generate.sh

# If there are changes to qix_generated.go then open a pull request
local_changes=$(git ls-files qix_generated.go -m)

if [ ! -z "$local_changes" ]; then
  git checkout -b $branch_name
  git add qix_generated.go
  git commit -m "Automated: New API based on $ENGINE_VERSION"
  git push -u origin $branch_name
  curl -u none:$GH_TOKEN https://api.github.com/repos/qlik-oss/enigma-go/pulls --request POST --data "{
        \"title\": \"Automated: Generated enigma-go based on new JSON-RPC API\",
        \"body\": \"Hello! This is an automated pull request.\n\nI have generated a new enigma-go based on the JSON-RPC API for Qlik Associative Engine version $ENGINE_VERSION.\",
        \"head\": \"$branch_name\",
        \"base\": \"master\"
      }"
  reset_to_master
else
  echo "No changes to schema."
fi
