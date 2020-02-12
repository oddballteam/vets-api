# frozen_string_literal: true

namespace :claims_status_lookup do

  desc 'whatever this is'
  task :go do
    # these values aren't local, create /WHEREVER/vets-api/config/settings.local.yml
    client = Aws::CloudWatchLogs::Client.new(
      region: Settings.evss.s3.region,
      access_key_id: Settings.evss.s3.aws_access_key_id,
      secret_access_key: Settings.evss.s3.aws_secret_access_key
    )

    # example from docs https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/CloudWatchLogs/Client.html#filter_log_events-instance_method
    # resp = client.filter_log_events({
    #   log_group_name: "LogGroupName", # required
    #   log_stream_names: ["LogStreamName"], # use this for a list of certain streams
    #   log_stream_name_prefix: "LogStreamName", #don't use with above, but can filter to certain streams
    #   start_time: 1, # time since epoch
    #   end_time: 1, # time since epoch
    #   filter_pattern: "FilterPattern",
    #   next_token: "NextToken", # used to pull back next set of logs
    #   limit: 1, # max to return, default is 10k
    #   interleaved: false, # deprecated
    # })

    resp = client.filter_log_events(
      log_group_name: "vets-api-server", # ???
      start_time: (Time.now - 1.hour).to_i * 1000, # I think it might accept `Time.now - 1.hour` here, but it wasn't clear
      filter_pattern: '{$.payload.path = "*evss*"}'
    )

    resp.event.each do |log_event|
      uuid = JSON.parse(log_event.message)['payload']['uuid_something'] # trying to do this from memory
    end
  end
end
