# Debrant 

[Debian](https://debian.org)-based web development [Vagrant](http://vagrantup.com), built on top of [10up/varying-vagrant-vagrants](https://github.com/10up/varying-vagrant-vagrants).

Our custom Vagrant box is a 190MB Debian Wheezy 32 bit installed via [grml-debootstrap](http://grml.org/grml-debootstrap/), with networking, VirtualBox additions and the basic tools. Everything else will be insalled via the custom provision bash scripts, which can be modified or replaced as needed.

Download: [wheezy32.box](http://tools.swergroup.com/downloads/wheezy32.box) (190MB)

## Features

* [Composer](http://getcomposer.org/) -- Dependency Manager for PHP
* Memcached
* Nginx
* [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer) -- tokenises PHP, JavaScript and CSS files and detects violations of a defined set of coding standards.
* [PHP_CodeCoverage](https://github.com/sebastianbergmann/php-code-coverage) -- Library that provides collection, processing, and rendering functionality for PHP code coverage information.
* [PHPunit](https://github.com/sebastianbergmann/phpunit/) -- de-facto standard for unit testing in PHP projects.
* [phpDocumentor](http://phpdoc.org/) -- generate API documentation for all features available in PHP 5.3 and higher.
* [Scrutinizer](https://github.com/scrutinizer-ci/scrutinizer) -- Library for abstracting the invocation of analysis tools.
* [wp-cli](wp-cli.org) -- command-line tools for managing WordPress installations.
* Pound
* Vagrant
* [Z shell (w/ GRML.org setup)](http://grml.org/zsh/)

## Mapped files/folders

* `config/sources.list` -- it replaces the main `/etc/apt/sources.list` file
* `config/custom-sources.list` -- optional `/etc/apt/sources.list.d/custom-sources.list` file
* `provision/provision-pre.sh` -- optional pre-default provision script (runs before, every time)
* `provision/provision-custom.sh` -- if present, replace the default provision script (and runs every time :-)
* `provision/provision.sh` -- default provision script (runs every time, unless custom is present)
* `provision/provision-post.sh` -- optional post-default provision script (runs before, every time)

* `config` -- shared configuration folder
* `database` -- database folders and scripts
* `www` -- website folders

