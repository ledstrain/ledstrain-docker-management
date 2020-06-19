# Flarum Docker Management

Use this to make it easier to host a local instance of a flarum forum using [docker-compose](https://docs.docker.com/compose/).

* Get the files:
```
git clone https://github.com/tyler71/flarum-docker-management
cd flarum-docker-management
mkdir site sqlbin
cp example.env .env
```
* Export your database and site files to `sqlbin/` and `site/`
  The sql export should be placed somewhere like `sqlbin/currentdate.sql`.  
   `site/` should have your site files. So you could reach `config.php` at `site/config.php`  
  If you're using mysql, see **Using Mysqsl** below
* Run `./devsite start` (or `just start`). The first time will take a little longer to build.
* Open up your site in the link provided!

This will allow you to view and login to your website. You will see a self-signed certificate warning, just accept it and continue. If you want to install plugins or upgrade, use `enter`
```
./devsite enter (or just enter)
```
This will drop you to the root directory of your flarum install. Now run `composer upgrade` or whatever you'd like.
After you've made the changes you wanted, exit out. Then if you want to update your hosted forum, just copy over `site/composer.json` and `site/composer.lock` to the hosted instance and run `composer install` (backup of course!)

Once you're done, just run
```
./devsite stop (or just stop)
```
This will tear everything down.
___

In the `.env` file, feel free to change these values if you like.  
Setting `SMTP_HOST` is used to nullify your SMTP hostname. This is helpful with cases where a plugin will send a email to a user. Something that you may not desire (for testing strike notices, for example).  
You *do not* need to set your mysql credentials in `.env`. The values in config.php are temporarily rewritten to match the ones in `.env` and the database `docker-compose` creates.

```
COMPOSE_PROJECT_NAME=projectname  # containers will show up as projectname_web_1
DEV_SITE=projectname.dev.xyzz.work # Make sure this resolves to 127.0.0.1
SMTP_HOST=smtp.email.host
```

#### Using Mysql

If you're using `mysql`, you will probably need one more change. In `docker-compose.yml`, you'll want to change `image: mariadb:10.3.23-bionic` to your mysql version. You can run `mysql -V` to see your version. 

```
$ mysql -V
mysql  Ver 8.0.20-0ubuntu0.20.04.1 for Linux on x86_64 ((Ubuntu))
```

So you'd replace `mariadb:10.3.23-bionic` with `mysql:8.0.20`  
The configuration should otherwise be the same.