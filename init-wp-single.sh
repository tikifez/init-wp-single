#!/bin/bash
if [ "$#" -gt 0 ]
	then
	if [ "$#" -lt 5 ]
		then
		echo "Please include all parameters.\
		wp_dir, db_host, db_user, db_pass, db_name"
		exit 1
	else
		wp_dir=$1
		db_host=$2
		db_user=$3
		db_pass=$4
		db_name=$5
	fi
else
	echo "Site directory: "
	read wp_dir

	echo "Database host (e.g. localhost, or localhost:3311): "
	read db_host

	echo "Database user: "
	read db_user

	echo "Database password: "
	read db_pass

	echo "Database name: "
	read db_name

fi

echo "Installing WordPress into $wp_dir"

echo "** Initializing the repository"
mkdir $wp_dir && cd $wp_dir
git init
touch README.md
git add README.md
git commit -m "Initial commit."

echo "** Cloning WordPress as a subrepository"
git submodule add git://github.com/WordPress/WordPress.git wordpress
git commit -m "Add WordPress subrepository."

echo "** Checking out WordPress v.3.9"
cd wordpress
git checkout 3.9
cd ..
git commit -am "Checkout WordPress 3.9"

echo "** Creating wp-config file"
cp wordpress/wp-config-sample.php wp-config.php
git add wp-config.php
git commit -m "Adding default wp-config.php file"

echo "** Configuring .htaccess file"
cd wordpress
touch .htaccess
cat <<EOF > .htaccess
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /onepress/wordpress/
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
EOF

echo "** Setting up wp-content directory"
cp -R wordpress/wp-content .
git add wp-content
git commit -m "Adding default wp-content directory"

echo "** Creating index.php"
cp wordpress/index.php .
git add index.php
git commit -m "Adding index.php"

echo "** Configuring core and site locations"
sed -i '' 's/\/wp-blog-header.php/\/wordpress\/wp-blog-header.php/g' index.php
git commit -am "Pointing index.php to the correct location"

echo "** Setting up database"
sed -i '' "s/database_name_here/$db_name/" wp-config.php
sed -i '' "s/username_here/$db_user/" wp-config.php
sed -i '' "s/password_here/$db_pass/" wp-config.php
sed -i '' "s/localhost/$db_host/" wp-config.php

echo "** Setting up keys"
COUNTER=0
while [  $COUNTER -lt 8 ]; do
	sed -i '' "1,/put your unique phrase here/s/put your unique phrase here/`LC_CTYPE=C tr -cd '[:alnum:]' < /dev/urandom | fold -w69 | head -n1`/" wp-config.php

	let COUNTER=COUNTER+1
done

echo "** Adding site location to wp-config"
echo "..."
var = "define('WP_SITEURL', 'http://' . $_SERVER['SERVER_NAME'] . '/$wp_dir/wordpress');\
define('WP_HOME',    'http://' . $_SERVER['SERVER_NAME'] . '/$wp_dir');\
\ ";
sed -i '' "16 a\
$var" wp-config.php
git commit -am "Update settings in wp-config.php"

echo "
** Processes done\\
**** Next steps: \\
**** 1. Set up your blog at wordpress/wp-admin/install.php\\
**** 2. Start blogging!
