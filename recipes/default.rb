# encoding: utf-8

# Copyright (c) 2014 Oracle and/or its affiliates. All rights reserved.
# $Id:$
#

# Cookbook Name:: oci_mcafee 
# Recipe:: default
#

Chef::Log.info '---'
Chef::Log.info "--- Cookbook: #{cookbook_name} / Recipe: #{recipe_name}"

# return if requested not to install
#
return if !node[:oci_mcafee][:installMcAfee]

Chef::Log.info ':instalMcAfee == true; proceeding to install'

dc_group = node[:oci_mcafee][:dc_group]

Chef::Log.info "#{dc_group} environment detected."

# Set up base system.
#
case
when node['platform_family'] == 'rhel'
    Chef::Log.info 'RHEL family detected. Using OL'
    
	if dc_group == "bmc" || dc_group == "oci2_0"
		include_recipe 'oci_mcafee::oraclelinux_2.0'
	else
		include_recipe 'oci_mcafee::oraclelinux'
	end

when node['platform_family'] == 'windows'
	case node['kernel']['os_info']['os_architecture']
	when '32-bit'
		Chef::Log.info 'Node is windows. 32bit detected.'
		include_recipe 'oci_mcafee::mcafee32bit'
	when '64-bit'
		Chef::Log.info 'Node is windows. 64bit detected.'
		if registry_key_exists?("HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\McAfee\\Agent", :x86_64) && ( dc_group == "bmc" || dc_group == "oci2_0" )
			include_recipe 'oci_mcafee::mcafee64bit_upgrade'
		else
			include_recipe 'oci_mcafee::mcafee64bit'
		end
	else
		Chef::Log.info 'Unsupported windows version'
	end
else
	Chef::Log.info "Unsupported platform family #{node['platform_family']}"
end