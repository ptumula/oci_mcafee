# encoding: utf-8

# Copyright (c) 2014 Oracle and/or its affiliates. All rights reserved.
# $Id:$
#

# Cookbook Name:: oci_mcafee
# Attributes:: default
#

# Attributes unique to the Node's environment, to be provided when chef-solo is invoked.
#

# McAfee Installer

if node['os'] == 'windows'
  default[:oci_mcafee][:mcafee_install][:dirname_url] = node[:oci_common][:depot_base_dirname_url] + '/automation/vendors/mcafee'
  default[:oci_mcafee][:mcafee_install][:basename] = node[:oci_mcafee][:windows_package] #'McAfeeSmartInstall.exe'
  default[:oci_mcafee][:mcafee_install][:installdir] = 'E:\\McAfee'
  default[:oci_mcafee][:mcafee_install][:installdirdata] = 'E:\\McAfee\\data'
else
  # assume linux otherwise
  default[:oci_mcafee][:mcafee_install][:depot_url] = node[:oci_common][:depot_base_dirname_url] + '/automation/vendors/mcafee'
  default[:oci_mcafee][:platform_version]['>= 7.0']['vsel_path'] = 'McAfeeVSEForLinux-2.0.3.29216-release-full.x86_64.tar.gz'

  default[:oci_mcafee][:platform_version]['< 7.0']['vsel_path'] = 'McAfeeVSEForLinux-1.9.2.29197-release-full.noarch.tar.gz'

  default[:oci_mcafee][:install_dir] = '/opt/NAI/LinuxShield'
  default[:oci_mcafee][:agent_dir] = '/opt/McAfee/agent'
  default[:oci_mcafee][:runtime_dir] = '/var/opt/NAI/LinuxShield'
  default[:oci_mcafee][:admin_email] = 'admin@example.com'
  default[:oci_mcafee][:http_port] = 55443
  default[:oci_mcafee][:monitor_port] = 65443
  default[:oci_mcafee][:skip_restart_flag] = '/var/lib/skip_mcafee_flag'
end

default[:oci_mcafee][:installMcAfee] = false
default[:oci_mcafee][:dc_group] = node[:oci_common][:dc_group]
default[:oci_mcafee][:LinuxRequiredVersion] = '5.0.6-220'
default[:oci_mcafee][:WindowsRequiredVersion] = '5.0.6.220'
	   
#**************************************Chef Server Integration Changes*****************************
if !node[:oci_platform].nil?
# Get Deployment variable value by name
def getDV(dvName,defaultValue=nil)
  if node[:oci_platform][:deploymentVariables]
    dvs = node[:oci_platform][:deploymentVariables]
    if !dvs.nil? && dvs.has_key?(:"#{dvName}")
      return dvs[:"#{dvName}"]
    end 
  end
  return defaultValue
end

# merge recursively 
def merge_recursively(old_hash,new_hash)
  target = old_hash
  if !new_hash.nil?
    new_hash.keys.each do |key|
      if old_hash[key].is_a? Hash and new_hash[key].is_a? Hash
        target[key] = merge_recursively(old_hash[key],new_hash[key])
        next      
      end
        target[key] = new_hash[key]
    end
  end
  return target
end

server_hash = Hash.new

chef_node_json = getDV('Chef Node Json')
if chef_node_json.class == Chef::Node::ImmutableMash
   merged_runlist_json = merge_recursively(server_hash,chef_node_json)
else
    puts "WARN :: Deployment variable Chef Node Json is not a valid Json Object. Skip merge node attributes operation."
    merged_runlist_json = server_hash
end

## Start Overriding Attributes ## 
  for key in merged_runlist_json.keys()
    override[key] = merged_runlist_json[key]
  end
end