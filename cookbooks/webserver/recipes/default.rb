execute 'apt-get-update' do
 command 'apt-get update'
 action :run
end

packages = [
	"nginx",
	"php",
	"php-fpm",
	"php-mysql",
	"php-curl", 
	"php-mbstring",
	"php-xml",
	"php-zip",
	"mysql-server",
	"git",
	"git-flow",
	"ssh",
	"screen"
]

packages.each do |pack|
        package "#{pack}" do
                action :install
        end
end

template "/etc/nginx/sites-available/webserver" do
        source "nginx.conf"
        owner "root"
        group "root"
        mode 0755
end

link "/etc/nginx/sites-enabled/webserver" do
  not_if "test -f /etc/nginx/sites-enabled/webserver"
  to "/etc/nginx/sites-available/webserver"
  action :create
  owner "root"
  group "root"
end

file "/etc/nginx/sites-enabled/default" do
  only_if "test -f /etc/nginx/sites-enabled/default"
  action :delete
end

Dirs = [
"/var/www/html/webserver",
"/var/www/html/webserver/public",
]

Dirs.each do |mydir|
	directory "#{mydir}" do
			action :create
			owner "root"
			group "root"
			mode 0755
			recursive true
	end
end

execute "chown-vagrant-www" do
  command "chown -R vagrant:www-data /var/www"
  user "root"
  action :run
end

bash "Install Composer" do
	user "root"
	not_if "test -f /usr/local/bin/composer"
	cwd "/var/www"
	code <<-EOH
		curl -sS https://getcomposer.org/installer | php
		mv /var/www/composer.phar /usr/local/bin/composer
		chown vagrant:vagrant /usr/local/bin/composer
        EOH
end

git "/var/www/laravel" do
  not_if "test -d /var/www/laravel"
  user "vagrant"
  group "www-data"
  repository "https://github.com/laravel/laravel.git"
  reference "master"
  action :sync
end

execute "Install Laravel" do
  user "vagrant"
  cwd "/var/www/laravel"
  command "composer install"
  user "vagrant"
  action :run
end

template "/var/www/laravel/.env" do
        source "env.erb"
        owner "vagrant"
        group "www-data"
        mode 0755
		variables({
			"name": "Laravel",
			"env": "local",
			"key": "nVlXjRaQky9gPuKBodII6+Ria86+CIYHpY2TDTq9u9o=",
			"url": "http://localhost",
			"mysql_host": "127.0.0.1",
			"mysql_database": "webserver",
			"mysql_username": "root",
			"mysql_password": "webserver",
		})
end

template "/var/www/laravel/resources/views/welcome.blade.php" do
        source "welcome.blade.php"
        owner "vagrant"
        group "www-data"
        mode 0755
end

execute "Laravel Cache Permissions" do
  user "vagrant"
  command "chmod 777 -R /var/www/laravel/bootstrap/cache /var/www/laravel/storage"
  action :run
end

#execute "Laravel Project Key" do
#  user "vagrant"
#  cwd "/var/www/laravel"
#  command "php artisan key:generate"
#  user "vagrant"
#  action :run
#end

execute "Restart PHP fpm" do
   command "systemctl restart php7.0-fpm"
end

execute "Restart Nginx" do
   command "systemctl restart nginx"
end

file "/var/www/html/webserver/public/info.php" do
  owner "root"
  group "www-data"
  mode 755
  action :create
  content "<?php echo phpinfo(); ?>"
end