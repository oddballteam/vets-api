unless Rails.env.production?
  # @see https://github.com/rubocop-hq/rubocop/blob/master/lib/rubocop/rake_task.rb
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new(:rubocop) do |task|
    task.patterns = %w('app config lib modules spec')

    if ENV['CI']
      task.requires = ['rubocop/formatter/junit_formatter.rb']
      task.formatters = [['RuboCop::Formatter::JUnitFormatter --out log/rubocop.xml'], 'clang']
    else
      task.options = ['--display-cop-names', '--safe-auto-correct']
    end
  end
end
