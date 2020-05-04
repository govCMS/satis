#!/usr/bin/env bash
IFS=$'\n\t'
set -euo pipefail

GOVCMS_SCAFFOLD="${GOVCMS_SCAFFOLD:-/tmp/govcms-build}"
SATIS_BUILD="${SATIS_BUILD:-/tmp/satis-build/app}"
BRANCH="${1:-}"
rm -Rf "${GOVCMS_SCAFFOLD}"

if [ ! -n "${1+set}" ] ; then
    config="govcms-stable.json"
else
    config="govcms-${1}.json"
fi
GOVCMS_VERSION=$(cat ./satis-config/${config} | jq -r '.require."govcms/govcms"')

echo -e "\033[1;35m--> Verifying packages for ${config} (govcms/govcms:${GOVCMS_VERSION}) \033[0m"

php -S localhost:4141 -t "${SATIS_BUILD}" > /tmp/phpd.log 2>&1 &
composer create-project --no-install govcms/govcms8-scaffold-paas "${GOVCMS_SCAFFOLD}"
# composer create-project --no-install --keep-vcs govcms/govcms8-scaffold-paas:dev-develop "${GOVCMS_BUILD}"

cd "${GOVCMS_SCAFFOLD}"
composer config secure-http false

echo -e "\033[1;35m\n--> Test building GovCMS against http://localhost:4141/${BRANCH}\033[0m"

# Ensure no conflicts with composer update.
rm -Rf vendor && rm -Rf web/core && rm -Rf web/modules/contrib/* && rm -Rf web/profiles/* rm composer.lock

# Replace satis.govcms.gov.au with local build.
composer config repositories.govcms composer http://localhost:4141/"${BRANCH}"
echo -e "\033[1;35m--> Repositories updated...\033[0m"
composer config repositories | jq .

# @todd: remove once govcms/govcms no longer requires "symfony/event-dispatcher:v4.3.11 as v3.4.35" which only works at the root composer.json level.
composer require --no-update symfony/event-dispatcher:"v4.3.11 as v3.4.35"

# Point to the appropriate versions.
if [ "${BRANCH}" = "master" ] || [ "${BRANCH}" = "develop" ] ; then   
   echo -e "\033[1;35m--> Updating package refereces to '${BRANCH}' branch \033[0m"
   COMPOSER_MEMORY_LIMIT=-1 composer require govcms/govcms:"${GOVCMS_VERSION}" govcms/require-dev:dev-"${BRANCH}" govcms/scaffold-tooling:dev-"${BRANCH}"
else
   COMPOSER_MEMORY_LIMIT=-1 composer require --no-suggest govcms/govcms:${GOVCMS_VERSION} govcms/require-dev:"${GOVCMS_VERSION_REQUIRE_DEV}" govcms/scaffold-tooling:"${GOVCMS_VERSION_SCAFFOLD_TOOLING}"
fi

composer -n update
composer validate
