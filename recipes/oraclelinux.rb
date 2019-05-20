# encoding: utf-8

# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

# Cookbook Name:: oci_mcafee
# Recipe:: oraclelinux

# Description: Installs McAfee Anti-Virus on a linux Server.

Chef::Log.info '---'
Chef::Log.info "--- Cookbook: #{cookbook_name} / Recipe: #{recipe_name}"

require 'chef/application'
require 'digest/sha2'

depot_url = node[:oci_mcafee][:mcafee_install][:depot_url]
installdir = node[:oci_mcafee][:mcafee_install][:installdir]
installdirdata = node[:oci_mcafee][:mcafee_install][:installdirdata]

agent_url = ""
vsel_url = ""
dl_name = ""
is_noarch = false
agent_path = ""

node[:oci_mcafee][:platform_version].each_key do |ver|
  if Chef::VersionConstraint.new(ver).include?(node['platform_version'])
    base = node[:oci_mcafee][:platform_version][ver][:base]
    if base.nil? || base.empty?
      base = '.'
    end
    agent_path =  node[:oci_mcafee][:agent_package]
    if agent_path.nil? || agent_path.empty?
      agent_path = 'agent_install.sh'
    end
    vsel_path =  node[:oci_mcafee][:platform_version][ver][:vsel_path]

    agent_url = "#{depot_url}/#{base}/#{agent_path}"
    vsel_url = "#{depot_url}/#{base}/#{vsel_path}"

    dl_name = File.basename(vsel_path)
    is_noarch = File.fnmatch?('*full.noarch*', dl_name)
  end
end

Chef::Log.info "- depot_url: #{depot_url}"
Chef::Log.info "- dl_name: #{dl_name}"
Chef::Log.info "- agent_path: #{agent_path}"
Chef::Log.info "- agent_url: #{agent_url}"
#Chef::Log.info "- base: #{base}"

#Checking for scriptname to append options
command_vsel='vsel_agent.sh'
if agent_path.include? "agent_install"
	command_vsel='vsel_agent.sh -i'
end

### Prereqs

# Required 32-bit libs and ed package
%w(pam.i686 libgcc.i686 ed zip).each do |pkg|
  package pkg do
    action :install
  end
end

# Install the agent
#
remote_file "#{Chef::Config[:file_cache_path]}/vsel_agent.sh" do
  mode '0755'
  source agent_url
  action :create
  notifies :run, 'execute[install_agent]', :immediately
  notifies :run, 'execute[remove_agent_installer]', :delayed
  not_if "rpm -qa | grep ^MFE"
end

execute 'install_agent' do
  cwd ::File.dirname(Chef::Config[:file_cache_path])
  command "#{Chef::Config[:file_cache_path]}/#{command_vsel}"
  ignore_failure true
  action :nothing
end

execute 'remove_agent_installer' do
  cwd ::File.dirname(Chef::Config[:file_cache_path])
  command "rm -f #{Chef::Config[:file_cache_path]}/vsel_agent.sh"
  action :nothing
end


dl_tgz = File.join(Chef::Config[:file_cache_path], dl_name)

mver=dl_name.split('-')[1]
mdistname=dl_name.split('-')[0]
install_cmd = "#{mdistname}-#{mver}-installer"
release_gz = ''
if is_noarch
  release_gz = "#{mdistname}-#{mver}-release.tar.gz"
  vse_tgz = dl_name.sub('-full.noarch', '')
  Chef::Log.info "noarch: - dl_name: #{dl_name}"
else
  release_gz = "#{mdistname}-#{mver}-release.tar.gz"
  vse_tgz = dl_name
  Chef::Log.info "not noarch - dl_name: #{dl_name}"
end

remote_file "#{Chef::Config[:file_cache_path]}/#{dl_name}" do
  source vsel_url
  action :create
  not_if "rpm -qa | grep ^McAfee"
end

execute 'unpack_noarch' do
  #only_if { is_noarch }
  cwd Chef::Config[:file_cache_path]
  command lazy { "tar xzvf #{File.basename(dl_tgz)}" }
  not_if "rpm -qa | grep ^McAfee"
  notifies :run, 'execute[cleanup_noarch]', :delayed
end

# Nails looks for its options file in /root
template '/root/nails.options' do
  source 'nails.options.erb'
  variables(
    install_dir: node[:oci_mcafee][:install_dir],
    runtime_dir: node[:oci_mcafee][:runtime_dir],
    admin_email: node[:oci_mcafee][:admin_email],
    http_port: node[:oci_mcafee][:http_port],
    monitor_port: node[:oci_mcafee][:monitor_port]
  )
end

# Install McAfee VSEL
#

execute "tar xzvf #{release_gz}" do
  cwd Chef::Config[:file_cache_path]
  command lazy { "tar xzvf #{File.basename(release_gz)}" }
  notifies :run, 'execute[cleanup_release_gz]', :delayed
  not_if "rpm -qa | grep ^McAfee"
end

execute "cleanup_release_gz" do
  cwd Chef::Config[:file_cache_path]
  action :nothing
  command lazy { "tar tzf #{File.basename(release_gz)} | xargs rm -f; rm -f #{File.basename(release_gz)}" }
end

execute "cleanup_noarch" do
  cwd Chef::Config[:file_cache_path]
  action :nothing
  command lazy { "tar tzf #{File.basename(dl_tgz)} | grep -v #{release_gz} | xargs rm -f; rm -f #{File.basename(dl_tgz)}" }
end

ENV['HOME'] = '/root'

execute "run #{install_cmd}" do
  cwd Chef::Config[:file_cache_path]
  command lazy { "bash ./#{install_cmd}" }
  not_if { ::Dir.exist?  node[:oci_mcafee][:runtime_dir] }
end

# Iterate index.html.* files, look for login/password form lines without autocomplete
# specified (default) and turn it off
# DCOPS docs call this "fix port vulnerability" and only do it for .en but, makes sense to
# do it for all.
ruby_block 'Fix-password-autocomplete' do
  block do
    html_glob = File.join(node[:oci_mcafee][:install_dir], 'apache', 'htdocs', 'index.html.*')
    md5_file = File.join(node[:oci_mcafee][:install_dir], 'etc', 'md5')
    md5_editor = Chef::Util::FileEdit.new(md5_file)

    Chef::Log.info('Looking indexes with autocomplete set for password...')
    updated_f = %w()
    Dir.glob(html_glob).each do |f|
      updated = false
          if !f.include? "old"
                  editor = Chef::Util::FileEdit.new(f)
                  Chef::Log.info("- Found index file #{File.basename(f)} checking...")
                  editor.search_file_replace(/(?<=id=user name=user tabindex=1) *>/, ' autocomplete=off>')
                  editor.search_file_replace(/(?<=id=password name=password tabindex=2) *>/, ' autocomplete=off>')
                  if editor.unwritten_changes? == true
                        updated = true
                        Chef::Log.info('-- File updated.')

                  else
                        Chef::Log.info('-- Autocomplete not found. Not updating.')
                  end
                  editor.write_file
          end

      if updated
        md5_editor.search_file_delete_line(File.basename(f))
        new_sum = Mixlib::ShellOut.new("md5sum #{f}")
        new_sum.run_command
        new_sum.error!
 
        newsum = new_sum.stdout.chomp
        Chef::Log.info("-- New MD5 Sum #{newsum}")
        md5_editor.insert_line_if_no_match(newsum, newsum)
      end
    end
    md5_editor.write_file
  end
end

ENV['HOME'] = '/root'

template '/usr/lib/systemd/system/nails.service' do
  source 'nails.service.erb'
  variables(
    install_dir: node[:oci_mcafee][:install_dir]
  )
  only_if { node[:platform_version].to_f >= 7.0 }
  notifies :run, 'bash[reload_domain]', :immediately
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
    bash 'stop_nails_srv' do
		code <<-EOH
		/opt/NAI/LinuxShield/bin/nails.initd stop
		service cma stop
		sleep 10
		EOH
		user 'root'
		action :run
		only_if { node[:platform_version].to_f >= 7.0 }
    end
	
    service 'nails-enable-restart' do
		service_name 'nails'
        action [ :enable, :restart ]
    end
		
    service 'cma-restart' do
		service_name 'cma'
        action :restart
		only_if { node[:platform_version].to_f >= 7.0 }
    end
end

service 'nails-restart' do
   service_name 'nails'
   action :restart
   not_if "service nails status | head -1 | grep -q 'is running'"
end

# Create skip_yum file so recipe will skip next time.
#
file node[:oci_mcafee][:skip_restart_flag] do
  content '0'
  owner 'root'
  group 'root'
end

# Reading nails password from encrypted data bag
if !node[:oci_platform].nil?
  require 'chef-vault'
  node.default[:oci_mcafee][:nails][:password] = ChefVault::Item.load("oci_mcafee", "ociclassic")
else
  node.default[:oci_mcafee][:nails][:password] = Chef::EncryptedDataBagItem.load("oci_mcafee", "ociclassic").to_hash
end

password = node.default[:oci_mcafee][:nails][:password]["nails_password"]
salt = rand(36**8).to_s(36)
shadow_hash = password.crypt("$6$" + salt)

user 'nails-password-update' do
  username 'nails'
  password shadow_hash
  action :modify
end