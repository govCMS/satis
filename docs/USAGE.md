# GovCMS Packagist - USAGE

## Benefits

1. The limited use of this packagist ensures that a project is GovCMS platform
compliant - particularly SaaS projects.

2. Since Satis does the hard work of resolving module versions, your 
`composer update` runs significantly faster.

3. By providing this packagist source, including an additional whitelist, we 
may have a way to reduce the (significant) size of the GovCMS distribution 
itself.

4. By using this as your only packagist source, you can ensure your Drupal
site is compatible with GovCMS, without having to rely on the GovCMS scaffold.
This is useful if you have a soft requirement for a future migration onto the
platform.

5. Other (government) organisations can leverage this packagist as a simple
way to limit modules on their own projects.


## Usage

The de facto usage looks like this in `composer.json`. There is no requirement
to add additional sources.

    
    "repositories": {
        "govcms": {
            "type": "composer",
            "url": "https://satis.govcms.gov.au/"
        },
        "govcms-whitelist": {
            "type": "composer",
            "url": "https://satis.govcms.gov.au/whitelist/"
        },
        "packagist.org": false
    },
    "require": {
        "govcms/govcms": "~1"
        "govcms/scaffold-tooling": "~1"
    }
    "require-dev": {
        "govcms/require-dev": "~1"
    }

### Breakdown of the above:

- `whitelist` is an additional whitelist of modules which are not in the GovCMS
  distribution. You may not be able to edit your `composer.json` to add these 
  packages.
- `"packagist.org": false` prevents adding modules and packages from 
  https://packagist.org.
- `"~1"` allows us to keep the `composer.json` requirements very loose 
  (best practice) as Satis has done the job of constraining the versions 
  already.


## How to ...

### ... use the latest release of GovCMS

If you are not hosting on the GovCMS platform you can still use the GovCMS
distribution by adding the code from the [Usage](#usage) section above. This 
also requires setting up your settings.php appropriate to your hosting solution.

### ... leverage the GovCMS Drupal settings

By requiring `govcms/scaffold-tooling` in your `composer.json` you can 
access GovCMS standard Drupal settings. The settings are available in
`vendor/govcms/scaffold-tooling/drupal` after running composer update.

See [settings.php](https://github.com/govCMS/govcms8-scaffold-paas/blob/develop/web/sites/default/settings.php)
in the Drupal 8 scaffold for guidance on using these files.

### ... use GovCMS distribution, but with the latest modules from Drupal.org

There are a number of modules in GovCMS which at not the latest
versions available. So is there a way to use the latest versions?

This is not a service provided by the GovCMS Satis/Packagist service. We
only support modules that have been through an internal review. If 
you use upgraded modules, we can't guarantee that there will be an
upgrade path.

Ask yourself why you need these updated modules. Is there a bug you
could patch instead? Can you wait for GovCMS to update?

If you are on PaaS, you can use an upcoming version of any module by manually
placing the whole module in `web/sites/default/modules/`. This location
overrides locations like `web/modules/contrib`. This is not the best practice
Drupal/Composer, but if this method helps PaaS customers remain close to a
"vanilla SaaS GovCMS" then it may be a valuable technique to add one or two 
modules.

*In this case PaaS customers are wholly responsible for managing updates and 
regressions.*

You can use the same method locally to test new module versions. We welcome
these tests so please let us know via the issue queue if you
encounter any issues.

### ... add modules not in GovCMS

If you are not hosting on the GovCMS platform, or if you are running
a PaaS site, you can add additional modules by adding Drupal packagist
in your repositories section, assuming they don't have version conflicts
with GovCMS.

Note that this shouldn't update the GovCMS module versions
because they are constrained by your `govcms/govcms:~1` requirement.

    "repositories": {
        ...
        "drupal ": {
            "type": "composer",
            "url": "https://packages.drupal.org/8"
        }


Add modules as desired.
    
    "require": {
        "govcms/govcms": "~1",
        "drupal/some-other-module": "~2",
        "vanilla-ice/some-dependencies-for-my-module": "~2",
        ...,
    }

You can also add references to other Git repositories using [Composer vcs type]
(https://getcomposer.org/doc/05-repositories.md#vcs).

Finally, you can choose to remove`"packagist.org": false` to access all the many
packages on [packagist.org](https://packagist.org). Remember that this *may* 
cause your Composer to pick up sub-packages which are newer than what GovCMS 
distribution stipulates (which is why it's not allowed on SaaS). If you are at 
this point you might as well re-architect with [drupal-composer/drupal-project](https://github.com/drupal-composer/drupal-project)
as your scaffold to get a more "custom vanilla" experience.
