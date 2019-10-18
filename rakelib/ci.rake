# frozen_string_literal: true

desc 'Runs the continuous integration scripts'
task ci: %i[lint:rubocop security danger spec:with_codeclimate_coverage]

task default: :ci

$stdout.sync = false
