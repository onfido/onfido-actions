#!/usr/bin/env bash

# Don't carry on when any command fails
set -e

TMP_FILE=$(mktemp)

RELEASE_VERSION=$(jq -r '.release' .release.json)
RELEASE_DATE=`date +'%dth %B %Y' | sed -E 's/^0//;s/^([2,3]?)1th/\11st/;s/^([2]?)2th/\12nd/;s/^([2]?)3th/\13rd/'`

SPEC_COMMIT_SHA=$(jq -r '.source.short_sha' .release.json)
SPEC_COMMIT_URL=$(jq -r '.source.repo_url + "/commit/" + .source.long_sha' .release.json)
SPEC_RELEASE_VERSION=$(jq -r '.source.version' .release.json)
SPEC_RELEASE_URL=$(jq -r '.source.repo_url + "/releases/tag/" + .source.version' .release.json)

# Changelog header
echo -e "# Changelog\n\n## $RELEASE_VERSION $RELEASE_DATE\n" >| $TMP_FILE

# Onfido OpenAPI reference release (or commit)
echo -en "- Release based on Onfido OpenAPI spec " >> $TMP_FILE

if [ -z $SPEC_RELEASE_VERSION ]; then
  echo "up to commit [$SPEC_COMMIT_SHA](${SPEC_COMMIT_URL}):" >> $TMP_FILE
else
  echo "version [$SPEC_RELEASE_VERSION](${SPEC_RELEASE_URL}):" >> $TMP_FILE
fi

# Add contents from github release notes body (lines starting with - only)
cat <<EOF | grep '^ *-' >> $TMP_FILE || true
$RELEASE_BODY
EOF

# Add contents from previous changelog and override it
grep -v "^# Changelog" CHANGELOG.md >> $TMP_FILE
mv $TMP_FILE CHANGELOG.md
