# encoding: utf-8
#

require 'spec_helper'

# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

def linux_packages(run) 
    expect(run).to install_package('pam.i686')
    expect(run).to install_package('libgcc.i686')

    expect(run).to install_package('ed')
end

describe 'oci_mcafee::default' do
  supported_platforms.each do |platform, versions|
    versions.each do |version|
      context "on #{platform.capitalize} #{version}" do
        let(:chef_run) do
          @chef_run
        end

        def depot_url 
          "http://depotURL"
        end

        context "Basic New Install" do
          before(:context) do
            @chef_run = ChefSpec::ServerRunner.new(platform: platform, version: version) do |node, server|
              node.default['oci_mcafee']['platform_version'] = test_versions
              node.default['oci_mcafee']['agent_install'] = true
              node.default['oci_mcafee']['mcafee_install']['depot_url'] = depot_url
            end
            @chef_run.converge(described_recipe)
          end

          it 'installs linux packages' do
            linux_packages(chef_run)
          end

          before(:each) do
            stub_command('./vsel.sh').and_return(true)
          end

          it "creates <CACHE_DIR>/vsel_agent.sh" do
            expect(chef_run).to create_remote_file(
              "#{Chef::Config[:file_cache_path]}/vsel_agent.sh")
          end

          it "executes ./vsel_agent.sh from <CACHE_DIR>" do
            expect(chef_run).to run_execute('./vsel_agent.sh').with(
              cwd: ::File.dirname(Chef::Config[:file_cache_path])
            )
          end

          test_versions.each do |k, v|
            if Chef::VersionConstraint.new(k).include?(version)
              it "creates <CACHE_DIR>/#{File.basename(v['vsel_path'])}" do
                expect(chef_run).to create_remote_file(
                  "#{Chef::Config[:file_cache_path]}/#{File.basename(v['vsel_path'])}")
              end

              release_tgz = File.basename(v['vsel_path'])
              if File.fnmatch('*noarch*', v['vsel_path'])
                release_tgz = release_tgz.sub('noarch', 'x86_64')
                it "Detects and unpacks the noarch archive" do
                  expect(chef_run).to run_execute(
                    "tar xzvf #{File.basename(v['vsel_path'])}").with(
                      cwd: "#{Chef::Config[:file_cache_path]}" )
                end

                it "unpacks the release" do
                  expect(chef_run).to run_execute(
                    "tar xzvf #{release_tgz}").with(cwd: "#{Chef::Config[:file_cache_path]}" )
                end
              else
                it "unpacks the release" do
                  expect(chef_run).to run_execute(
                    "tar xzvf #{File.basename(v['vsel_path'])}").with(cwd: "#{Chef::Config[:file_cache_path]}" )
                end
              end

              # Silent install file contains all options
              it 'creates /root/nails.options' do
                expect(chef_run).to create_template('/root/nails.options').with(
                  source:  'nails.options.erb',
                )
                # Check for defaults
                %w(
              SILENT_HTTPPORT="55443"
              SILENT_MONITORPORT="65443"
              SILENT_SMTPPORT="25"
                ).each do |match|
                  expect(chef_run).to render_file('/root/nails.options').with_content(/^#{match}/)
                end
              end

              it 'executes the installer' do
                expect(chef_run).to run_execute(install_command(File.basename(v['vsel_path'])))
              end

              it 'runs a ruby block to update autocomplete' do
                expect(chef_run).to run_ruby_block('Fix-password-autocomplete')
              end

              it 'restarts nails' do
                expect(chef_run).to restart_service('nails')
              end
            end 
          end
        end
      end
    end
  end
end

def install_command(name) 

  base = name.split('-')[0]
  ver = name.split('-')[1]

  "#{base}-#{ver}-installer"
end
