# Presto Checks

This project defines build automation for Presto that is meant to be run periodically / for a selection of commits in selected branches.

## Requirements
- bash
- [aws cli](https://github.com/aws/aws-cli#installation)
- [travis cli](https://github.com/travis-ci/travis.rb#installation)
- access to https://api.travis-ci.org/ from the machine you're executing `trigger_checks_for_latest_build.sh`
- `$REPO` - the slug of the repo where you're reading this, probably `Teradata/presto-checks`
- `$TOKEN` - Travis token obtained by executing `travis --token` in this repo's dir

## Triggering and operation

The travis build is meant to be triggered via API, using the `trigger_checks_for_latest_build.sh` script. 
You can ping it from your machine, maybe from crontab on a server, from a Jenkins job, or wherever where the [requirements](#requirements) are met.

Usage:
```
trigger_checks_for_latest_build.sh \
  $CHECKS_GITHUB_REPO \
  $CHECKS_REPO_TRAVIS_TOKEN \
  $CHECKS_BRANCH \
  $PRESTO_BRANCH
```
where:
 - `CHECKS_GITHUB_REPO` - this repo's slug, in format ${ORGANIZATION}/${REPO_NAME} (changes across forks)
 - `CHECKS_REPO_TRAVIS_TOKEN` - the result of executing `travis --token` by a user having access to this repo (changes across forks)
 - `CHECKS_BRANCH` - branch of this repo to use. Most of the time it will be `master` or `sprint`. Useful for adding a feature branch in this repo, e.g. to add a new set of checks.
 - `PRESTO_BRANCH` - branch of Teradata/presto repo to use for artifacts download. The latest artifacts built for given branch will be used. Can be `@{LATEST_SPRINT_BRANCH}` which will resolve to the latest `sprint-##` branch.

So far, the build defined in `.travis.yml` will:

1. Download the latest Presto artifacts built by Teradata/presto for branch `$PRESTO_BRANCH`
2. Run the product tests in configurations specified in `.travis.yml`
3. Upload results links to `travis_checks` folder in the folder from which the artifacts were downloaded ([example](http://teradata-presto.s3.amazonaws.com/index.html?prefix=travis_build_artifacts/Teradata/presto/sprint-37/3040.4/travis_checks/))

## Use cases

### Running thorough yet lengthy tests periodically / on demand

- for sprint a sprint branch:
```
trigger_checks_for_latest_build.sh $REPO $TOKEN sprint sprint-37
```
This will dowload the latest **artifacts and product tests** for `sprint-37` from [Teradata's s3](teradata-presto.s3.amazonaws.com/index.html?prefix=travis_build_artifacts/Teradata/presto/) and run the product tests using the long-running configurations defined in `travis.yml` (more precisely, the version available on `sprint` branch of the `$REPO`)

- for master branch:
```
trigger_checks_for_latest_build.sh $REPO $TOKEN master master
```

- for the **latest sprint branch**:
```
trigger_checks_for_latest_build.sh $REPO $TOKEN sprint @{LATEST_SPRINT_BRANCH}
```

- for a feature branch:
```
trigger_checks_for_latest_build.sh $REPO $TOKEN master feature/awseome
```

- for a feature branch in this repo (e.g. when adding new set of tests to be run):
```
#if you're developing the new tests against Presto master
trigger_checks_for_latest_build.sh $REPO $TOKEN feature/moar_tests master

#or if you're developing against a sprint/feature branch
trigger_checks_for_latest_build.sh $REPO $TOKEN feature/moar_tests feature/awesome
```
