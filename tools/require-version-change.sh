#!/bin/bash

# To ensure commits with modified maps always update _metadata.version,
# create a .git/hooks/pre-commit script that includes
# `exec tools/require-version-change.sh` as one of its lines.

errors=0
while read -r line; do
  MODIFIED=`git diff --staged "$line" | grep '^[+-]    "version":' | wc -l`
  if [[ $MODIFIED == 0 ]]; then
    echo "_metadata.version update required in $line"
    ((errors++))
  fi
done < <(git diff --name-only --staged | grep '\.map\.json')

if (( errors != 0 )); then
	echo "Please update ${errors} modified maps."
	exit 1
fi

echo "Verified that any modified maps have updated _metadata.version."
