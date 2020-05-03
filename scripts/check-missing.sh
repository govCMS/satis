#!/usr/bin/env bash
IFS=$'\n\t'
set -euo pipefail

SATIS_BUILD="${SATIS_BUILD:-./app}"
GOVCMS_BUILD="${GOVCMS_BUILD:-/tmp/satis-check-missing}"
BRANCH="${1:-}"
rm -Rf "${GOVCMS_BUILD}"

if [ ! -n "${1+set}" ] ; then
    config="govcms-stable.json"
else
    config="govcms-${1}.json"
fi
GOVCMS_VERSION=$(cat ./satis-config/${config} | jq -r '.require."govcms/govcms"')

echo -e "\033[1;35m--> Check missing packages for ${config} - govcms/govcms: ${GOVCMS_VERSION}  \033[0m"

# Set up a working project and satis server.
php -S localhost:4142 -t "${SATIS_BUILD}" > /tmp/phpd.log 2>&1 &
composer create-project --no-install --keep-vcs govcms/govcms8-scaffold-paas:dev-develop "${GOVCMS_BUILD}"
cd "${GOVCMS_BUILD}"
composer config secure-http false

# Ensure no conflicts with composer update.
rm -Rf vendor && rm -Rf web/core && rm -Rf web/modules/contrib/* && rm -Rf web/profiles/* rm composer.lock

# Install raw govcms with standard repositories avaiable to us.
# This is a bit messy, `composer config repositories` is (at this time) flexible when controlling "packagist.org":false etc, and also jq is not an in-place editor.
cp composer.json composer-copy.json && cat composer-copy.json \
  | jq .repositories='{"drupal":{"type":"composer","url": "https://packages.drupal.org/8"},"custom":{"type":"path","url":"custom/composer"},"govcms":{"type":"composer","url":"http://localhost:4142/'"${BRANCH}"'"}}' \
  | tee composer.json > /dev/null

# Add in dependency alias at composer root for solarium 5.x
composer require --no-update symfony/event-dispatcher:"v4.3.11 as v3.4.35"

# Point composer.json the appropriate branch versions if testing develop or master.
if [ "${BRANCH}" = "master" ] || [ "${BRANCH}" = "develop" ] ; then
    echo -e "\033[1;35m--> Updating govcms packages to their '${BRANCH}' versions \033[0m"
    composer config prefer-stable true
    COMPOSER_MEMORY_LIMIT=-1 composer require --no-suggest govcms/govcms:${GOVCMS_VERSION} govcms/require-dev:dev-"${BRANCH}" govcms/scaffold-tooling:dev-"${BRANCH}"
fi
echo -e "\033[1;35m--> Please wait for composer update  \033[0m"
COMPOSER_MEMORY_LIMIT=-1 composer update --no-suggest --quiet

composer info
composer why govcms/govcms

# Get a list of the package versions that `composer update` resolved via normal repositories.
target_list=$(composer info --format=json | jq -r '.installed[] | "\(.name) \(.version)"' | sort)

# Now point the project to the local satis build.
cp composer.json composer-copy.json && cat composer-copy.json \
  | jq .repositories='{"govcms":{"type":"composer","url":"http://localhost:4142/'"${BRANCH}"'"},"packagist.org":false}' \
  | tee composer.json > /dev/null

# Clean up all the installed things from the previous step, because they give false positives when searching satis for packages.
rm -Rf vendor web/core web/modules/custom composer.lock

echo -e "\033[1;35m--> Now checking each desired package against satis \033[0m"
suggestions=""

for target in $target_list
do
    project=$(echo "${target}" | cut -d" " -f1)
    version=$(echo "${target}" | cut -d" " -f2)
    if [ "${project}" != "govcms/custom" ]; then
        set +e
        match=$(composer show "${project}" --all --format=json 2>/dev/null | jq -r '.versions[] | select(. == "'"${version}"'")')
        set -e
        if [ "${version}" = "${match}" ]; then
            echo -e "\033[1;32mPackage found:\033[0m ${project}:${version}"
        else
            echo -e "\033[1;91mMissing package:\033[0m ${project}:${version}"
            suggestions="${suggestions}    \"${project}\": \"${version}\",\n"
        fi
    fi
done

name="${BRANCH:-stable}"
if [ ! -z "$suggestions" ]; then
    echo -e "\033[1;35m"
    echo "Additional 'requires' for ./satis-config/govcms-${name}.json"
    echo "These items have not resolved properly in the satis build."
    echo "Re-run 'ahoy build-${name}' and 'ahoy verify-${name}' after modifying satis config."
    echo -e "\033[0m"
    echo '"require": {'
    echo -e "${suggestions}"
fi
