#!/bin/sh

export PHP_POST_MAX_SIZE=${PHP_UPLOAD_MAX_FILESIZE:-50m}

sed -i "s@50m@${PHP_UPLOAD_MAX_FILESIZE:-50m}@g" /opt/docker/etc/nginx/vhost.common.d/10-general.conf

if [ ! -f /app/config/config.php ]; then
	mv /app/config.example.php /app/config/config.php
	ln -s /app/config/config.php /app/config.php
else
	if [ -f /app/config.example.php ]; then
		mv /app/config.example.php /app/config/config-newversion.php
	fi
	if [ ! -f /app/config.php ]; then
		ln -s /app/config/config.php /app/config.php
	fi
fi

sed -i "s@https:\/\/localhost@$URL@g" /app/config.php
sed -i "s/return\ \[/&\n\ \ \ \ \'app_name\' => \'$APP_NAME\',/" /app/config.php

if [ "${DB_TYPE:-sqlite}" == "mysql" ]; then
	sed -i "s/sqlite/mysql/g" /app/config.php
	sed -i "s/realpath(__DIR__).'\/resources\/database\/xbackbone.db'/'host=$MYSQL_HOST;dbname=$MYSQL_DATABASE;charset=utf8mb4'/g" /app/config.php
	sed -i "s/'username'   => null/'username'   => '$MYSQL_USER'/g" /app/config.php
	sed -i "s/'password'   => null/'password'   => '$MYSQL_PASSWORD'/g" /app/config.php
fi

if [ ! -f /app/storage/.installed ]; then
	su -c "php /app/bin/migrate --install" $CONTAINER_UID
	su -c "php /app/bin/migrate" $CONTAINER_UID
	su -c "php /app/bin/clean" $CONTAINER_UID
	echo '-' > /app/storage/.installed
else
	su -c "php /app/bin/migrate" $CONTAINER_UID
        su -c "php /app/bin/clean" $CONTAINER_UID
fi

chown -R $CONTAINER_UID /app
