# GovCMS Packagist - MAINTENANCE

## What is it

There are four satis servers which are built from four config files (in 
`./satis-config`).
These can be used in the "repositories" section of `composer.json`.

|   |   |   |
| --- | --- | --- |
| `STABLE` | `govcms-stable.json` | https://satis.govcms.gov.au/ |
| `MASTER` | `govcms-master.json` | https://satis.govcms.gov.au/master |
| `DEVELOP` | `govcms-develop.json` | https://satis.govcms.gov.au/develop |
| `WHITELIST` | `govcms-whitelist.json` | https://satis.govcms.gov.au/whitelist |

They are updated by running `ahoy build` which populates the `./app` directory
with static files.

## Updating content

Updating of the Satis repository content is a manual process that includes 
running a set of command locally and committing regenerated content directly
to the repository. 

Updating `STABLE` should be done when there is a new minor release of GovCMS.

Updating `MASTER` and `DEVELOP` should be done when the `master` and `develop`
branches are updated on
 * [govcms/govcms8](https://github.com/govCMS/govcms8)
 * [scaffold-tooling](https://github.com/govCMS/scaffold-tooling)
 * [require-dev](https://github.com/govCMS/require-dev)
  

## Running the automated scripts

Each of the `ahoy build`, `ahoy check-dupes`, `ahoy verify` and `ahoy debug` 
commands can accept any of the current versions (`stable`, `master` or 
`develop`) as a parameter. Providing no parameter is equivalent to `stable`.  
There is also a `-all` variant to these commands that will run the process for 
all branches. 

## Update MASTER

This will update the `./app/master` directory.

1. Clean `./satis-config/govcms-master.json` by removing:

    * extra packages from `require` - only leave the first three `govcms/*` 
      packages
    * the `blacklist` section - remove completely

2. Run `ahoy build master` to update /app.

3. Run `ahoy verify master` - it will likely fail.

4. Run `ahoy debug master` - follow instructions.

5. Re-run `ahoy build master` and `ahoy verify master` (ie. repeat the above 
   steps as needed).

## Update DEVELOP

This will update the `./app/develop` directory. Repeat the exact steps you 
followed to update MASTER, just replace `master` with `develop`.

1. Clean `./satis-config/govcms-develop.json` by removing:

    * extra packages from `require` - only leave the first three `govcms/*`
      packages
    * the `blacklist` section - remove completely

2. Run `ahoy build develop` to update /app.

3. Run `ahoy verify develop` - it will likely fail.

4. Run `ahoy debug develop` - follow instructions.

5. Re-run `ahoy build develop` and `ahoy verify develop` (ie. repeat the above 
   steps as needed).

## Update STABLE

This will update the `./app` directory. You are repeating the steps you followed 
to update MASTER, just replace `master` with `stable`.

There is only one extra step (step 2).


1. Clean `./satis-config/govcms-stable.json` by removing:

    * extra packages from `require` - only leave the first three `govcms/*` 
      packages
    * the `blacklist` section - remove completely

2. *ONLY FOR STABLE* update the package versions for the `govcms/*` versions 
   to the latest versions.

3. Run `ahoy build stable` to update /app.

4. Run `ahoy verify stable` - it will likely fail.

5. Run `ahoy debug stable` - follow instructions.

6. Re-run `ahoy build stable` and `ahoy verify stable` (ie. repeat the above 
   steps as needed).

## Steps to update WHITELIST

This is a hassle free one because it doesn't calculate dependencies. 
Run `ahoy build-whitelist`.

## Additional troubleshooting steps

To quickly see if there are any duplicates in your package.json files, 
`ahoy check-dupes { stable|master|develop }`.

## Push

Once you have updated all branches, create a PR to https://github.com/govcms/satis. 

Once this is merged it will trigger
quay.io to rebuild an image (see `docker-compose.yml`).

## Technical notes

This project is built on top of [composer/satis](https://github.com/composer/satis) 
using the Docker image. The following settings are important because it forces 
Satis to resolve an *ideal* set of package versions.

    "require-dependencies": true,
    "require-dev-dependencies": true,
    "only-best-candidates": true
