# frozen_string_literal: true

return if Rails.env.production?

task(:spec).clear

MODULE_SPEC_PATHS = 'modules/*/spec/**/*_spec.rb'
SPEC_PATHS        = 'spec/**/*_spec.rb'

desc 'vets-api | rspec | Run all tests'
RSpec::Core::RakeTask.new(:spec, :rspec_opts) do |t, args|
  t.pattern = Dir.glob([MODULE_SPEC_PATHS, SPEC_PATHS])
  t.verbose = false
  t.rspec_opts = args[:rspec_opts]
end

namespace :spec do
  desc 'vets-api | rspec | Run unit tests'
  RSpec::Core::RakeTask.new(:unit, :rspec_opts) do |t, args|
    t.rspec_opts = args[:rspec_opts]
  end

  desc 'run rspec tests and report results to CodeClimate'
  task with_codeclimate_coverage: :environment do
    if ENV['CC_TEST_REPORTER_ID']
      puts 'notifying CodeClimate of test run'
      system('/cc-test-reporter before-build')
    end

    begin
      Rake::Task['spec'].invoke
    rescue SystemExit => e
      status = e.status
    end

    if ENV['CC_TEST_REPORTER_ID']
      puts 'reporting coverage to CodeClimate'
      system('/cc-test-reporter after-build -t simplecov')
    end

    exit(status)
  end
end
