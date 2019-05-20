# encoding: utf-8

# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

# Cookbook Name:: oci_mcafee
# Recipe:: oraclelinux_2.0

# Description: Installs McAfee Anti-Virus on a oci2.0, bmc linux Server.

Chef::Log.info '---'
Chef::Log.info "--- Cookbook: #{cookbook_name} / Recipe: #{recipe_name}"

require 'chef/application'

agent_path =  node[:oci_mcafee][:agent_package]
depot_url = node[:oci_mcafee][:mcafee_install][:depot_url]
agent_url = "#{depot_url}/#{agent_path}"

Chef::Log.info "agent_url: #{agent_url}"

# Convert required version

$r_version = node[:oci_mcafee][:LinuxRequiredVersion]
$r_version = $r_version.gsub('.', '').gsub('-', '')
$r_version = $r_version.to_i

# Pre-checking MFEcma if it's installed
mfe_Check = Mixlib::ShellOut.new("yum list installed | grep -i MFEcma | awk {'print $2'} | sed 's/[.-]//g'")
mfe_Check.run_command
mfe_Check.error!

# ruby_block to be able to recall the mfe_Check
ruby_block 'mfe_checking' do
    block do
        mfe_Check = Mixlib::ShellOut.new("yum list installed | grep -i MFEcma | awk {'print $2'} | sed 's/[.-]//g'")
        mfe_Check.run_command
        mfe_Check.error!
    end
    action :nothing
end

remote_file "#{Chef::Config[:file_cache_path]}/#{agent_path}" do
	mode '0755'
	source agent_url
	action :create
	notifies :run, 'execute[unzip_agentPackage]', :immediately
	notifies :run, 'execute[remove_agent_installer]', :delayed
	only_if { mfe_Check.stdout.to_i < $r_version }
end

execute 'unzip_agentPackage' do
    cwd Chef::Config[:file_cache_path]
    command lazy { "unzip -o #{File.basename(agent_path)}" }
    action :nothing
end

execute 'install_agent' do
    cwd ::File.dirname(Chef::Config[:file_cache_path])
    command "bash #{Chef::Config[:file_cache_path]}/install.sh -i"
    ignore_failure true
    notifies :run, 'ruby_block[mfe_checking]', :immediately
    not_if "rpm -qa | grep ^MFE"
end

execute 'upgrade_agent' do
    cwd ::File.dirname(Chef::Config[:file_cache_path])
    command "bash #{Chef::Config[:file_cache_path]}/install.sh -b"
    ignore_failure true
    notifies :run, 'ruby_block[mfe_checking]', :delayed
    only_if { mfe_Check.stdout.to_i < $r_version }
end

template '/usr/lib/systemd/system/cma.service' do
  source 'cma.service.erb'
  only_if { node[:platform_version].to_f >= 7.0 }
  notifies :run, 'bash[reload_domain]', :immediately
end

bash 'reload_domain' do
  code <<-EOH
  /usr/bin/systemctl daemon-reload
  EOH
  user 'root'
  action :nothing
end

unless File.exist?(node[:oci_mcafee][:skip_restart_flag])
    bash 'stop_cma_srv' do
		code <<-EOH
		service cma stop
		sleep 10
		EOH
		user 'root'
		action :run
		only_if { node[:platform_version].to_f >= 7.0 }
    end
		
    service 'cma-restart' do
		service_name 'cma'
        action :restart
		only_if { node[:platform_version].to_f >= 7.0 }
    end
end

service "cma" do
	action :enable
end

service "cma_restart" do
	service_name 'cma'
	action :restart
	not_if "service cma status | head -2 | grep -q 'already running'"
end

execute 'remove_agent_installer' do
    cwd Chef::Config[:file_cache_path]
    command "zipinfo -1 #{File.basename(agent_path)} | xargs rm -f; rm -f #{File.basename(agent_path)}"
    action :nothing
end

# Create skip_yum file so recipe will skip next time.
#
file node[:oci_mcafee][:skip_restart_flag] do
  content '0'
  owner 'root'
  group 'root'
end
