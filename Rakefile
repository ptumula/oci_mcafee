# encoding utf-8

# Copyright (c) 2014 Oracle and/or its affiliates. All rights reserved.
# $Id:$
#

# Cookbook Name:: oci_windows (OCI Windows)
# Rakefile
#
# Usage:
# % rake -T   (To list rake targets).

desc 'Default Task'
task :default => [:lint_ruby]

desc 'Run Ruby and Chef Cookbook linters.'
task :lint_all do
  Rake::Task["lint_cookbook"].execute
  Rake::Task["lint_ruby"].execute
end

desc 'Run Chef Cookbook linter (foodcritic) on the cookbook.'
task :lint_cookbook do
  puts "Running foodcritic on the cookbook."
  sh "foodcritic #{Dir['.'][0]}"
end

desc 'Run Ruby linter (rubocop) on all Ruby files in the cookbook.'
task :lint_ruby do
  puts 'Running rubocop on all Ruby Files'
  Dir['attributes/*.rb', 'definitions/*.rb', 'libraries/*.rb', 'recipes/*.rb', 'resources/*.rb', 'providers/*.rb'].each do |f|
    begin
      sh "rubocop #{f}"
    rescue
      puts "Encountered errors in #{f}."
      puts ''
    end
  end
end
