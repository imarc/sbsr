SBSR (Share, Build, Sync, Release) is a generic web application deployment recipe and
configuration that works with [deployer](https://deployer.org/).  It uses a common workflow and
tasks which can be customized via a simple YAML configuration.

## Requirements

It is assumed you have the following installed:

- Git
- PHP (Deployer Compatible Version)
- Composer

## Installing

As root, create a deployment user:

```bash
useradd -rm deploy
```

Become the user:

```bash
su - deploy
```

Install deployer:

```bash
composer global require deployer/deployer
```

Clone SBSR:

```bash
git clone https://github.com/imarc/sbsr.git
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

As root, ceate a directory for your deployments:

```bash
mkdir /var/www/example.com
```

Copy the SBSR `deploy.yml` example into it:

```bash
cp /home/deploy/sbsr/deploy.yml /var/www/example.com/
```

Give your deploy user full domain over this fold directory.  It is strongly suggested that you use
ACLs to handle permissions since it enables default permissions to be added automatically:

```bash
chown -R deploy:deploy /var/www/example.com
setfacl -R -dm u:deploy:rwx /var/www/example.com
setfacl -R -m u:deploy:rwx /var/www/example.com
```

## Configuration

Please see the heavily commented [deploy.yml](deploy.yml) file for configuration details and
examples.


## Usage

Set up a stage.  Default stages are `dev`, `uat`, and `prod`:

```bash
dep setup <stage>
```

Deploying to a stage:

```bash
dep to <stage>
```

## Notes

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

$dotenv = new Dotenv\Dotenv(__DIR__);
$dotenv->load();

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
