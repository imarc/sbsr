SBSR (Share, Build, Sync, Release) is a generic web application deployment recipe and
configuration that works with [deployer](https://deployer.org/).  It uses a common workflow and
tasks which can be customized via a simple YAML configuration.

## Requirements

It is assumed you have the following installed:

- Git
- PHP (Deployer Compatible Version)
- Composer

## Usage

If you're looking for how to install, skip to [installing](#installing).

### NOTE

> _**All usage commands must be executed in the project folder where deployment was setup (the location of the `deploy.yml` file).  At current, you cannot specify to deploy a specific site from another location.**_

### Deployment

Deploying to a stage:

```bash
dep to <stage>
```

### Database

Create a new database for the stage.  This will create a database such as `<stage>_<db.name>_new`
which:

```bash
dep db:create <stage>
```

You can now run whatever manual operations you need to on the database.  If you make a mistake you
can drop the new database:

```bash
dep db:drop <stage>
```
> Note: that this will only drop the new database.  Once a database is rolled out, there's no way
using SBSR to remove it.  You can only ever roll out a new database in its place.

If all your operations were run successfully, you can roll out the new database to the current:

```bash
dep db:rollout <stage>
```

> Note: This will move `<stage>_<db.name>`, if it exists, to `<stage>_<db.name>_old` and move the
new `<stage>_<db.name>_new` to `<stage>_<db.name>`, basically cycling the databases.

If you want to import a database you can execute the following:

```bash
dep db:import -I <file> <stage>
```

This will create a new database, and execute the SQL found in `<file>`.  Keep in mind you still
will need to roll it out to replace the current database.

To export a database, run:

```bash
dep db:import -O <file> <stage>
```

## Installing

As root, create a deployment user:

```bash
useradd -rm deploy
```

Become the user:

```bash
su - deploy
```

Clone SBSR:

```bash
git clone https://github.com/imarc/sbsr.git
```

Enter directory:

```bash
cd sbsr
```

Install Deployer and Dependencies:

```
composer install
```

Exit to return to root:

```
exit
```

Link the proxy command:

```
ln -s /home/deploy/sbsr/deploy.sh /usr/bin/dep
```

## Initializing a Deployment Space

As root, create a directory for your deployments:

```bash
mkdir /var/www/example.com
```

Give your deploy user full domain over this fold directory.  It is strongly suggested that you use
ACLs to handle permissions since it enables default permissions to be added automatically:

```bash
chown -R deploy:deploy /var/www/example.com
setfacl -R -dm u:deploy:rwx /var/www/example.com
setfacl -R -m u:deploy:rwx /var/www/example.com
```

Become the deployment user:

```bash
su - deploy
```

Enter the directory:

```bash
cd /var/www/example.com
```

Copy the SBSR `deploy.yml` example into it:

```bash
cp /home/deploy/sbsr/deploy.yml ./
```

Edit the config accordingly.  The `deploy.yml` example is heavily commented and explains each of
the options in detail:

```bash
<editor> deploy.yml
```

Save and exit your editor.  You can now set up your stages:

```bash
dep setup <stage>
```

Usually you will begin by setting up the production environment:

```bash
dep setup prod
```

This will create the requisite stage directories for `prod`, copy out any shares that exist in
your version control repository to the shares directory for the stage, and create/rollout a new
database for the stage.



## Concepts

### Build

(v.) The process of compiling a web site or application.  In SBSR, this step is completed by a list
of arbitrary commands.

### Release

(n.) A release is a functional deployment of the web site or application.  More strictly speaking,
it is a _revision_ of the code exported to a _stage_.  Basically, it is the product of deployment.

(v.) The process in which the web site or application goes live.  In SBSR, this step includes
data migrations to post-launch cleanup.

### Revision

(n.) A revision is a particular version of the web site or application code.

### Share

(n.) A share is a file or directory that lives outside of version control and is shared across
multiple deployments.  Common shares include `.env` files, session / storage folders, etc.

(v.) The process of linking _shares_ to a _release_ during deployment.

### Source

(n.) A source is a _stage_ to which another _stage_ is synchronized during deployment.  For example
you may wish, upon deploying `dev` to make sure that it synchronizes its database and user uploaded
files from `prod`.

### Stage

(n.) A stage is an environment where a web site or application may be put on display for viewing.
A single site or application may have one or more "stages," e.g. `dev`, `uat`, `prod`.

### Sync

(v.) The process in which data and _shares_ are synchronized between a _stage_ and its _source_.




## Technical Notes

### Postgres

The configured database user (default `postgres`, the root user) will need permission to create
databases.  If you're using the `postgres` user, it is strongly suggested that you use `pg_hba.conf`
to enable the user to connect in a `peer` or `trusted` fashion to prevent having the password
configured in your `deploy.yml`.

If you wish to change this user, you can give them permission to create databases with:

`ALTER USER {{ user }} CREATDB;`

### Migrations

SBSR does not support migrations directly, however, it does support the automatic execution of
`phinx`.  When databases are synced, prior to the new database being rolled out, it will attempt to
run `phinx status` and check if the return is `0`.  In order to integrate phinx wit SBSR, you will
need a configuration that is implicitly tied to a given stage's `.env` database settings and,
rather than having all stages listed as environments, provide environments for `current`, `new`,
and `old`.

```php
<?php

include('vendor/autoload.php');

//
// Test if .env exists.  We don't need it to create a migration, so this can fail in some cases
// but we still want that functionality.
//

if (file_exists(__DIR__ . '/.env')) {
	$dotenv = new Dotenv\Dotenv(__DIR__);
	$dotenv->load();
}

return [
	'paths' => [
		'migrations' => __DIR__ . '/database/migrations',
		'seeds'      => __DIR__ . '/database/seeds'
	],
	'environments' => [
		'default_migration_table' => 'phinxlog',
		'default_database' => 'current',
		'current' => [
			'adapter' => 'pgsql',
			'host'    => getenv('DB_HOST') ?: 'localhost',
			'name'    => getenv('DB_NAME'),
			'user'    => getenv('DB_USER') ?: 'web',
			'pass'    => getenv('DB_PASS')
		],
		'new' => [
			'adapter' => 'pgsql',
			'host'    => getenv('DB_HOST') ?: 'localhost',
			'name'    => getenv('DB_NAME') . '_new',
			'user'    => getenv('DB_USER') ?: 'web',
			'pass'    => getenv('DB_PASS')
		],
		'old' => [
			'adapter' => 'pgsql',
			'host'    => getenv('DB_HOST') ?: 'localhost',
			'name'    => getenv('DB_NAME') . '_old',
			'user'    => getenv('DB_USER') ?: 'web',
			'pass'    => getenv('DB_PASS')
		]
	],
];
```
