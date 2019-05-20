# encoding: utf-8

# Copyright (c) 2014 Oracle and/or its affiliates. All rights reserved.
#

# Cookbook Name:: oci_mcafee (OCI McAfee Cookbook)
# Recipe:: oci_config_log.rb
#

Chef::Log.info '---'
Chef::Log.info "--- Cookbook: #{cookbook_name} / Recipe: #{recipe_name}"

platform_family = node[:platform_family]

dc_group = node[:oci_mcafee][:dc_group]
service_name= "masvc"
service_name_ape= "Mcafee Agent"
agent_dir = node[:oci_mcafee][:agent_dir]
agent_dir_win = node[:oci_mcafee][:mcafee_install][:installdir]

unless node[:oci_mcafee][:installMcAfee]
  oci_common_config_log '** McAfee Agent Service **' do
    feature 'McAfee Agent Service'
    commands ['echo "Mcafee Agent is disabled to install"']
    cookbook_config_name run_context.cookbook_collection[cookbook_name].metadata.name
    cookbook_config_version run_context.cookbook_collection[cookbook_name].metadata.version
    action :add_entry
  end
else
# Run correct recipe per platform.
#
case platform_family
  when 'rhel'
    template "#{Chef::Config[:file_cache_path]}/mcafee-log.sh" do
	  source "mcafee-log.sh.erb"
	  mode '0755'
      action :create 
	  		variables({
			:dc_group => dc_group,
			:agent_dir => agent_dir
		})
    end
    oci_common_config_log '**  McAfee Agent Service **' do
      feature 'McAfee Agent Service'
      commands ["#{Chef::Config[:file_cache_path]}/mcafee-log.sh"]
      cookbook_config_name run_context.cookbook_collection[cookbook_name].metadata.name
      cookbook_config_version run_context.cookbook_collection[cookbook_name].metadata.version
      action :add_entry
    end
	
  when 'windows'
    template "#{Chef::Config[:file_cache_path]}/mcafee-log.cmd" do
	  source "mcafee-log.cmd.erb"
      action :create
	  		variables({
			:service_name => service_name,
			:dc_group => dc_group,
			:agent_dir => agent_dir_win,
			:service_name_ape => service_name_ape
		})
    end
    oci_common_config_log '**  McAfee Agent Service **' do
      feature 'McAfee Agent Service'
      commands ["#{Chef::Config[:file_cache_path]}/mcafee-log.cmd"]
      cookbook_config_name run_context.cookbook_collection[cookbook_name].metadata.name
      cookbook_config_version run_context.cookbook_collection[cookbook_name].metadata.version
      action :add_entry
    end
	
  else
    Chef::Log.error "Unsupported platform: #{platform_family}"
    Chef::Application.fatal! "Unsupported platform: #{platform_family}" 
  end
end