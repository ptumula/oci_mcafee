# encoding: utf-8

# Copyright (c) 2014 Oracle and/or its affiliates. All rights reserved.
# $Id:$
#

# Cookbook Name:: oci_mcafee
# Recipe:: mcafee64bit_upgrade
#

# Description: Installs McAfee Anti-Virus on a Windows Server.
#

Chef::Log.info '---'
Chef::Log.info "--- Cookbook: #{cookbook_name} / Recipe: #{recipe_name}"

require 'chef/application'

dirname_url = node[:oci_mcafee][:mcafee_install][:dirname_url]
basename = node[:oci_mcafee][:mcafee_install][:basename]

## Get currently installed version ##
# Load Agent registry key into ruby hash array
mcafee_version = registry_get_values("HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\McAfee\\Agent", :x86_64)

# Get AgentVersion binary value

mcafee_version.each do |key|
  if key[:name] == "AgentVersion"
    $version = key[:data]
  end
end

# Transofrm and convert variable to integer
$c_version = $version.gsub('.', '')
$c_version = $c_version.to_i

## Populate required version ##
# Load predefined variable and convert it to integer

$r_version = node[:oci_mcafee][:WindowsRequiredVersion]
$r_version = $r_version.gsub('.', '')
$r_version = $r_version.to_i

Chef::Log.info "Current Mcafee Version--- #{$c_version}"
Chef::Log.info "Required Mcafee Version--- #{$r_version}"

return if $c_version >= $r_version

# Download McAfee installer
#
remote_file "#{Chef::Config[:file_cache_path]}\\#{basename}" do
  source "#{dirname_url}/#{basename}"
end

# Upgrade McAfee
#
windows_package "Upgrade Mcafee" do
    action    :install
    installer_type    :custom
	source    "#{Chef::Config[:file_cache_path]}\\#{basename}"
	#options '/INSTALL=UPDATER /SILENT'
end

#Delete McAfee installer
file "#{Chef::Config[:file_cache_path]}\\#{basename}" do
  action :delete
end