# frozen_string_literal: true

# REVIEW name of this task namespace (and file name)
namespace :claims_status_lookup do

  desc 'PUT A GREAT DESCRIPTION HERE'
  task :go do
    # these values aren't local, create /WHEREVER/vets-api/config/settings.local.yml for development
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

    # holds uuids without repeats
    uuids = Set.new

    # these are the log events we want
    query = {
      log_group_name: "vets-api-server", # ???
      start_time: (Time.now - 1.hour).to_i * 1000, # I think it might accept `Time.now - 1.hour` here, but it wasn't clear
      filter_pattern: '{$.payload.path = "*evss*"}',
      limit: 1_000_000
    }

    # get the events
    resp = client.filter_log_events(query)
    while(resp.events.any?) # keep using next_token until we have all the events
      next_token = resp.next_token
      resp.events.each do |log_event|
        # adds uuid to set of uuids
        uuids << JSON.parse(log_event.message)['payload']['uuid_something'] # trying to do this from memory
      end
      resp = client.filter_log_events(query.merge(next_token: next_token))
    end

    # build array for CSV data
    information = [["IDme UUID", "EDIPI"]]
    information += Account.where(idme_uuid: uuids).pluck(:idme_uuid, :edipi)

    # write CSV
    File.open("PATH/TO/FILE.csv", 'w') do |file|
      file.write(information.to_csv)
    end
  end
end
