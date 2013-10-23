# Debrant 

Debrant (Debian Vagrant) is a [Debian](https://debian.org)-based web development and learning [Vagrant](http://vagrantup.com) project, heavily inspired ( = half forked ) from [10up/varying-vagrant-vagrants](https://github.com/10up/varying-vagrant-vagrants). Please note: it's a work in progress.

Our custom Vagrant box is a 32-bit Debian Wheezy VM built via [grml-debootstrap](http://grml.org/grml-debootstrap/) with networking, VirtualBox additions and the base system; everything else (~250MB) will be installed via the custom provision bash scripts, which can be modified or replaced as needed.

Vagrant box direct download: [wheezy32.box](http://tools.swergroup.com/downloads/wheezy32.box) (188MB)

## Features

### Server stack

* [Memcached](http://memcached.org)
* [Nginx](http://nginx.org)
* [Node.js](http://nodejs.org)
* [Percona Server](http://www.percona.com/software/percona-server)
* [PHP5](http://php.net)
* [Pound](http://www.apsis.ch/pound)
* [Varnish](https://www.varnish-cache.org)
* [Z shell (w/ GRML.org setup)](http://grml.org/zsh/)

### WP/PHP Development

* [Composer](http://getcomposer.org/) -- Dependency Manager for PHP
* [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer) -- tokenises PHP, JavaScript and CSS files and detects violations of a defined set of coding standards.
* [PHP_CodeCoverage](https://github.com/sebastianbergmann/php-code-coverage) -- Library that provides collection, processing, and rendering functionality for PHP code coverage information.
* [PHPunit](https://github.com/sebastianbergmann/phpunit/) -- de-facto standard for unit testing in PHP projects.
* [phpDocumentor](http://phpdoc.org/) -- generate API documentation for all features available in PHP 5.3 and higher.
* [Scrutinizer](https://github.com/scrutinizer-ci/scrutinizer) -- Library for abstracting the invocation of analysis tools.
* [wp-cli](wp-cli.org) -- command-line tools for managing WordPress installations.


## Mapped files/folders

* `config/sources.list` -- it replaces the main `/etc/apt/sources.list` file
* `config/custom-sources.list` -- optional `/etc/apt/sources.list.d/custom-sources.list` file
* `provision/provision-pre.sh` -- optional pre-default provision hook script
* `provision/provision-custom.sh` -- if present, replace the default provision script
* `provision/provision.sh` -- default provision script (runs every time, unless custom is present)
* `provision/provision-post.sh` -- optional post-default provision hook script

* `config` -- shared configuration folder
* `database` -- database folders and scripts
* `shared` -- shared plugins/themes folder
* `www` -- website folders


## Changelog

### 0.1.0 (23/Ott/2013)

* Global setup

