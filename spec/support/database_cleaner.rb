# frozen_string_literal: true

class DirtyDatabaseError < RuntimeError
  def initialize(meta)
    super "#{meta[:full_description]}\n\t#{meta[:location]}"
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:deletion)
  end

  config.before(:all, :cleaner_for_context) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.before do |example|
    next if example.metadata[:cleaner_for_context]

    DatabaseCleaner.strategy =
      if example.metadata[:js]
        :transaction
      else
        example.metadata[:strategy] || :transaction
      end

    DatabaseCleaner.start
  end

  config.after do |example|
    next if example.metadata[:cleaner_for_context]

    DatabaseCleaner.clean
  end

  config.after(:all, :cleaner_for_context) do
    DatabaseCleaner.clean
  end
end
