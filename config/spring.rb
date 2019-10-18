# frozen_string_literal: true

Spring.watch 'config/application.yml'
Spring.watch 'config/settings.yml'
Spring.watch 'config/settings.local.yml'

require 'spring/application'

# patch for parallel tests
# https://github.com/grosser/parallel_tests/wiki/Spring
class Spring::Application
  alias connect_database_orig connect_database

  def connect_database
    disconnect_database
    reconfigure_database
    connect_database_orig
  end

  def reconfigure_database
    if active_record_configured?
      ActiveRecord::Base.configurations =
        Rails.application.config.database_configuration
    end
  end
end

# rspec test randomization is broken when using spring
#
# @see https://github.com/rails/spring/issues/113#issuecomment-427162116
Spring.after_fork do
  if Rails.env.test?
    RSpec.configure do |config|
      config.seed = srand % 0xFFFF unless ARGV.any? { |arg| arg =~ /seed/ }
    end
  end
end
