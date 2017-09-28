execute 'apt-get-update' do
 command 'apt-get update'
 ignore_failure true
end

packages = [
	"nginx",
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
    
execute "Restart Nginx" do
   command "systemctl restart nginx"
end