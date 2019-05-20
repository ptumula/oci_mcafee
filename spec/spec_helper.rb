# spec_helper.rb
require 'chefspec'
#require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.formatter = :documentation
  config.color = true

  # Specify the path for Chef Solo to find roles (default: [ascending search])
  # config.role_path = '/var/roles'

  # Specify the Chef log_level (default: :warn)
  # config.log_level = :info

  # Specify the path to a local JSON file with Ohai data (default: nil)
  # config.path = 'ohai.json'
end

def supported_platforms
  platforms = {
    'oracle' => ['6.5','7.2'],
  }
end

def test_versions
  test_env = {
    '>= 7.0' => {
      'base' => 'software/DCOps/AV_Client',

      'agent_path' => 'VSEL2.0',
      'vsel_path' => 'VSEL1.9/McAfeeVSEForLinux-2.0.3.29216-release-full.x86_64.tar.gz'
    },
    '< 7.0' => {
      'base' => 'software/DCOps/AV_Client',
      'agent_path' => 'VSEL2.0',
      'vsel_path' => 'VSEL2.0/McAfeeVSEForLinux-1.9.2.29197-release-full.noarch.tar.gz'
    }
  }
end

at_exit { ChefSpec::Coverage.report! }
