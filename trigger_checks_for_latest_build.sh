#!/usr/bin/env bash

if [[ $# -ne 4 ]]; then
  echo 'Usage: trigger_checks_for_latest_build.sh $CHECKS_GITHUB_REPO $CHECKS_REPO_TRAVIS_TOKEN $CHECKS_BRANCH $PRESTO_BRANCH'
  echo ''
  echo 'Passing $PRESTO_BRANCH = `@{LATEST_SPRINT_BRANCH}` will trigger checks for the latest sprint branch.'
  exit 1
fi

CHECKS_GITHUB_REPO=${1/\//%2F}
CHECKS_REPO_TRAVIS_TOKEN=$2
CHECKS_BRANCH=$3
PRESTO_BRANCH=$4

ARTIFACTS_S3_BUCKET='teradata-presto'
ARTIFACTS_S3_PATH='travis_build_artifacts/Teradata/presto'

if [[ "$PRESTO_BRANCH" == '@{LATEST_SPRINT_BRANCH}' ]]; then
    PRESTO_BRANCH=`aws s3 ls s3://${ARTIFACTS_S3_BUCKET}/${ARTIFACTS_S3_PATH}/ --no-sign-request | awk '{print $2}' | sed 's/.$//' | egrep '^sprint-[0-9]+$' | sort -n -t '-' -k 2 | tail -n1`
    echo "Current sprint branch resolved to [${PRESTO_BRANCH}]"
fi

PRESTO_BUILD=`aws s3 ls s3://${ARTIFACTS_S3_BUCKET}/${ARTIFACTS_S3_PATH}/$PRESTO_BRANCH/ --no-sign-request | awk '{print $2}' | sed 's/.$//' | sort -n | tail -n1`

BODY=$(cat << EOF
{
  "request": {
    "message": "Checks for Presto branch [$PRESTO_BRANCH] build [$PRESTO_BUILD]",
    "branch": "$CHECKS_BRANCH",
    "config": {
      "before_install": [
        "export ARTIFACTS_S3_BUCKET='$ARTIFACTS_S3_BUCKET'",
        "export ARTIFACTS_S3_PATH='$ARTIFACTS_S3_PATH'",
        "export PRESTO_BRANCH='$PRESTO_BRANCH'",
        "export PRESTO_BUILD='$PRESTO_BUILD'"
      ]
    }
  }
}
EOF
)

echo "Sending the following request:"
echo $BODY
echo "Response was:"

curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token $CHECKS_REPO_TRAVIS_TOKEN" \
  -d "$BODY" \
  https://api.travis-ci.org/repo/$CHECKS_GITHUB_REPO/requests
