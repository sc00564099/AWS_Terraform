#!/usr/bin/env bash
function check_randomized {
  if [ ! -f interview_id.txt ]; then
    echo "Codebase is not randomized yet. Please run ./recops.sh randomize first"
    exit 5
  fi
}

function randomize {
  if [ -f interview_id.txt ]; then
    >&2 echo "Codebase was already randomized. Skipping"
  else
    >&2 echo "Randomizing the code base..."
    : "${CODE_PREFIX?Required, set it to candidate\'s lastname}"
    echo "${CODE_PREFIX}" > interview_id.txt
    INTERVIEW_CODE=$(cat interview_id.txt)
    >&2 find ./infra -type f -exec sed -i "s/news4321/news$INTERVIEW_CODE/g" {} \;
  fi
}
