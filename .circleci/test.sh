#!/usr/bin/env bash
##
## Test that GovCMS scaffold can be built using Satis.
##

# shellcheck disable=SC2002,SC2015

# Satis application directory.
APP_DIR="${APP_DIR:-./app}"

# The branch of Satis to test against.
SATIS_BRANCH="${SATIS_BRANCH:-}"

# Directory where scaffold is installed into.
GOVCMS_SCAFFOLD_DIR="${GOVCMS_SCAFFOLD_DIR:-/tmp/govcms-build}"

#-------------------------------------------------------------------------------

echo "--> Starting Satis web server on http://localhost:4141."
killall -9 php > /dev/null 2>&1  || true
php -S localhost:4141 -t "${APP_DIR}" > /tmp/phpd.log 2>&1 &
sleep 4 # Waiting for the server to be ready.
netstat_opts='-tulpn'; [ "$(uname)" == "Darwin" ] && netstat_opts='-anv' || true;
netstat "${netstat_opts[@]}" | grep -q 4141 || (echo "ERROR: Unable to start inbuilt PHP server" && cat /tmp/php.log && exit 1)
curl -s -o /dev/null -w "%{http_code}" -L -I http://localhost:4141 | grep -q 200 || (echo "ERROR: Server is started, but site cannot be served" && exit 1)

echo "--> Cloning govcms8-scaffold-paas into ${GOVCMS_SCAFFOLD_DIR}."
rm -Rf "${GOVCMS_SCAFFOLD_DIR}"
composer create-project --no-install --quiet govcms/govcms8-scaffold-paas "${GOVCMS_SCAFFOLD_DIR}"

composer --working-dir="${GOVCMS_SCAFFOLD_DIR}" config secure-http false

echo
echo "--> Test build GovCMS against http://localhost:4141/${SATIS_BRANCH}."
echo

echo "--> Add http://localhost:4141/${SATIS_BRANCH} as a repository."
composer --working-dir="${GOVCMS_SCAFFOLD_DIR}" config repositories.govcms composer http://localhost:4141/"${SATIS_BRANCH}"

if [ "${SATIS_BRANCH}" = "master" ] || [ "${SATIS_BRANCH}" = "develop" ] ; then
  php -d memory_limit=-1 "$(command -v composer)" --working-dir="${GOVCMS_SCAFFOLD_DIR}" require --no-update \
      govcms/govcms:1.x \
      govcms/scaffold-tooling:dev-"${SATIS_BRANCH}" \
      govcms/require-dev:dev-"${SATIS_BRANCH}" \
      symfony/event-dispatcher:"v4.3.11 as v3.4.35" # @todo: remove once govcms/govcms no longer requires "symfony/event-dispatcher:v4.3.11 as v3.4.35" which only works at the root composer.json level.
else
  # Get package versions required for testing stable release.
  version_govcms="$(cat "./satis-config/govcms-stable.json" | jq -r '.require | .["govcms/govcms"]')"
  version_tooling="$(cat "./satis-config/govcms-stable.json" | jq -r '.require | .["govcms/scaffold-tooling"]')"
  version_require_dev="$(cat "./satis-config/govcms-stable.json" | jq -r '.require | .["govcms/require-dev"]')"

  echo "--> Expected stable versions, based on the Satis config:"
  echo "    - govcms/govcms:           ${version_govcms}"
  echo "    - govcms/scaffold-tooling: ${version_tooling}"
  echo "    - govcms/require-dev:      ${version_require_dev}"
  php -d memory_limit=-1 "$(command -v composer)" --working-dir="${GOVCMS_SCAFFOLD_DIR}" require --no-update \
      govcms/govcms:"${version_govcms}" \
      govcms/scaffold-tooling:"${version_tooling}" \
      govcms/require-dev:"${version_require_dev}" \
      symfony/event-dispatcher:"v4.3.11 as v3.4.35" # @todo: remove once govcms/govcms no longer requires "symfony/event-dispatcher:v4.3.11 as v3.4.35" which only works at the root composer.json level.
fi

echo "--> Contents of composer.json after dependency resolution."
cat "${GOVCMS_SCAFFOLD_DIR}"/composer.json | jq .require

echo "--> Assert that Composer update works."
php -d memory_limit=-1 "$(command -v composer)" --working-dir="${GOVCMS_SCAFFOLD_DIR}" -n --quiet --no-suggest --no-scripts update

echo "--> Assert that govcms* dependencies present."
composer --working-dir="${GOVCMS_SCAFFOLD_DIR}" info | grep ^govcms
