#!/usr/bin/env bash

# We are updating version number only when:
# - not a pull request
# - branch name is = develop or branch name is like release/vX.X.X...
if [ "${TRAVIS_REPO_SLUG}" = "${UTPLSQL_REPO}" ] && [ "$TRAVIS_PULL_REQUEST" == "false" ] && [[ "${CURRENT_BRANCH}" =~ ^(release/v[0-9]+\.[0-9]+\.[0-9]+.*|develop)$ ]]; then
    echo Current branch is "${CURRENT_BRANCH}"
    echo "Committing version & buildNo into branch (${CURRENT_BRANCH})"
    git add sonar-project.properties
    git add VERSION
    git add source/*
    git add docs/*
    git commit -m 'Updated project version after build [skip ci]'
    echo "Pushing to origin"
    git push --quiet origin HEAD:${CURRENT_BRANCH}
else
    echo "Publishing of version skipped for branch ${CURRENT_BRANCH}, pull request ${TRAVIS_PULL_REQUEST}"
fi
