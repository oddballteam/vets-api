# frozen_string_literal: true

unless Rails.env.production?
  require 'rainbow'

  namespace :lint do
    desc 'vets-api | lint | Run rails_best_practices'
    task :rails_best_practices do
      Rake::Task['rails_best_practices'].invoke
    end

    desc 'vets-api | lint | Run reek'
    task :reek do
      Rake::Task['reek'].invoke
    end

    desc 'vets-api | lint | Run rubocop'
    task :rubocop do
      Rake::Task['rubocop'].invoke
    end

    desc 'vets-api | lint | Run several lint checks'
    task :all do
      status = 0

      tasks = %w[
        lint:rubocop
        lint:rails_best_practices
        lint:reek
      ]

      tasks.each do |task|
        pid = Process.fork do
          begin
            puts Rainbow("*** Running task: #{task} ***").cadetblue

            Rake::Task[task].invoke
          rescue SystemExit => e
            warn Rainbow("!!! Task #{task} exited:").red
            raise e
          rescue StandardError, ScriptError => e
            warn Rainbow("!!! Task #{task} raised #{ex.class}:").bg(:red).white
            raise e
          end
        end

        Process.waitpid(pid)
        status += $?.exitstatus
      end

      exit(status)
    end
  end
end
