# encoding: utf-8

# Copyright (c) 2014 Oracle and/or its affiliates. All rights reserved.
# $Id:$
#

# Cookbook Name:: oci_mcafee
# Recipe:: mcafee64bit
#

# Description: Installs McAfee Anti-Virus on a Windows Server.
#

Chef::Log.info '---'
Chef::Log.info "--- Cookbook: #{cookbook_name} / Recipe: #{recipe_name}"

require 'chef/application'

dirname_url = node[:oci_mcafee][:mcafee_install][:dirname_url]
basename = node[:oci_mcafee][:mcafee_install][:basename]
installdir = node[:oci_mcafee][:mcafee_install][:installdir]
installdirdata = node[:oci_mcafee][:mcafee_install][:installdirdata]
dc_group = node[:oci_mcafee][:dc_group]

#check if it's already install and bail 
#
return if registry_key_exists?("HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\McAfee\\Agent", :x86_64)


# Download McAfee installer
#
remote_file "#{Chef::Config[:file_cache_path]}\\#{basename}" do
  source "#{dirname_url}/#{basename}"
   not_if { registry_key_exists?("HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\McAfee\\Agent", :x86_64) }
end

if dc_group == "bmc" || dc_group == "oci2_0"
	# Install McAfee 
    windows_package "Install Mcafee" do
        action    :install
        installer_type    :custom
		source    "#{Chef::Config[:file_cache_path]}\\#{basename}"
		options '/INSTALL=AGENT /SILENT'
        not_if { registry_key_exists?("HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\McAfee\\Agent", :x86_64) }
    end
else
	# Create cmd file to run mcafee install
	template "#{Chef::Config[:file_cache_path]}\\mcafee.cmd" do
		source "mcafee.cmd.erb"
		# copy attributes to variables that can be used in the erb file
		variables({
			:chefCachLoc => Chef::Config[:file_cache_path],
			:basename => basename,
			:installdir => installdir,
			:installdirdata => installdirdata
		})
		not_if { registry_key_exists?("HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\McAfee\\Agent", :x86_64) }
	end

	# Install McAfee 
	#
	execute 'Install McAfee' do
		command "#{Chef::Config[:file_cache_path]}\\mcafee.cmd "
		action :run
		not_if { registry_key_exists?("HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\McAfee\\Agent", :x86_64) }
	end
end

execute "Check Add Remove Programs" do
  command "wmic product list brief | findstr /i /c:\"McAfee\" "
  action :run
  only_if { registry_key_exists?("HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\McAfee\\Agent", :x86_64) }
end 

#Delete McAfee installer
file "#{Chef::Config[:file_cache_path]}\\#{basename}" do
  action :delete
end

#Delete McAfee installer
file "#{Chef::Config[:file_cache_path]}\\mcafee.cmd" do
  action :delete
end