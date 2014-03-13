#
# Cookbook Name:: my-jboss
# Recipe:: default
#
# Copyright 2014, Vladimir Mironov, EPAM Systems
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'java'

group = node['my_jboss']['group']
user = node['my_jboss']['user']
home = node['my_jboss']['home']

group group do
    action [ :create, :manage ]
end

user user do
    action [ :create, :manage ]
    comment 'jboss user'
    gid group
    home home
    shell '/usr/sbin/nologin'
    supports :manage_home => true 
end

directory home do
    owner user
    group group
    mode 00755
    recursive true
    action :create
end


directory "#{Chef::Config['file_cache_path']}" do
    mode 00755
    recursive true
    action :create
end

#bash 'mk-cache' do
##    user user
##    group group
#code <<-EOH
#mkdir -p #{Chef::Config['file_cache_path']}
#EOH
#end

# Download the archive
# http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip
remote_file "#{Chef::Config['file_cache_path']}/#{node['my_jboss']['product']}-#{node['my_jboss']['version']}.#{node['my_jboss']['release']}.tar.gz" do
  owner user
  group group
  mode 00644
  action :create_if_missing
  source "#{node['my_jboss']['mirror']}/#{node['my_jboss']['version']}/#{node['my_jboss']['product']}-#{node['my_jboss']['version']}.#{node['my_jboss']['release']}/#{node['my_jboss']['product']}-#{node['my_jboss']['version']}.#{node['my_jboss']['release']}.tar.gz"
end

bash 'extract-jboss' do
    user user
    group group
    cwd home
code <<-EOH
rm -rf *
tar xzf #{Chef::Config['file_cache_path']}/#{node['my_jboss']['product']}-#{node['my_jboss']['version']}.#{node['my_jboss']['release']}.tar.gz
mv #{node['my_jboss']['product']}-#{node['my_jboss']['version']}.#{node['my_jboss']['release']}/* #{home}/
rm -rf #{node['my_jboss']['product']}-#{node['my_jboss']['version']}.#{node['my_jboss']['release']}
EOH
end

template "/etc/init.d/jboss" do
  if platform? ["centos", "redhat"]
    source "init_el.erb"
  else
    source "init_deb.erb"
  end
  mode "0755"
  user "root"
  owner "root"
  group "root"
end

# start service
service 'jboss' do
  action [ :enable, :start ]
end

