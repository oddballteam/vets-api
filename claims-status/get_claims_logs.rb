#!/usr/bin/env ruby
# frozen_string_literal: true

# requires jq and awslogs
# not a good script yet
# very dumb
require 'pry'
require 'csv'

SGROUP="dsva-vagov-prod/srv/vets-api/src/log/vets-api-server.log"

max = 30
start_time = max
end_time   = start_time - 1

# Server logs
server_command = `awslogs get #{SGROUP} \
  --start="#{start_time.to_s}d ago" \
  --end="#{end_time.to_s}d ago" \
  --filter-pattern '{$.payload.path = "*evss*"}'
 sed 's/^.*|\(.*$\)/\1/' | \
 jq '[.payload.user_uuid, .named_tags.request_id, .payload.path, .payload.status|tostring] | join(", ")'`
 # then the jq processing to make a series of CSV with the following values (for uniquiness checking)

output_file_name = "#{start_time.days.ago}_claims_requests_by_user_uuid.csv"

# Get last 6 hours of logs
awslogs get dsva-vagov-prod/srv/vets-api/src/log/vets-api-server.log --start="1h ago" --filter-pattern '{$.payload.path = "*evss*"}' > claims.log

# Add headers
echo "user_uuid, request_id, path, status" > claims_log.csv

# Remove all but the JSON
# Pipe the JSON through jq to extract our requested values
sed 's/^.*|\(.*$\)/\1/' -i claims.log && \
  cat claims.log | \
  jq -r '[.payload.user_uuid, .named_tags.request_id, .payload.path, .payload.status|tostring] | join(", ")' \
  >> claims_log.csv && \
  awk '!a[$0]++' claims_log.csv # dedupe based on uuid

# Ruby way of deduping
# CSV.open("out.csv", 'w') do |csv|
  # CSV.read('10m.csv').uniq{|x| x[0]}.each do |row|
    # csv << row
  # end
# end

table = CSV.table("out.csv")
uuids = table[:user_uuid]
# edipis = Account.where(idme_uuid: uuids).map(&:edipi)
output_csv_data = []
Account.where(idme_uuid: uuids).in_batches.each_record { |x| output_csv_data[0] = x.edipi }

edipis.zip uuids

### 2020-02-13
uuids = CSV.table("14day-claims-deduped.csv")[:user_uuid]
report = []

File.open("report.csv", "w") { |f| f << "EDIPI, IDME_UUID\n" }

uuids.each_slice(1000) do |slice|
  # results = Account.where(edipi: lines).pluck(:edipi)
  results = Account.where(idme_uuid: slice).pluck(:edipi, :idme_uuid)
  report += results

  CSV.open("report.csv", "a+") do |csv|
    batch.each do |line|
      csv << line
    end
  end
end


######cat 2020-01-31.2020-02-13.evss.claims-status.json | jq -r '[.payload.user_uuid, .timestamp, .named_tags.request_id, .payload.path, .payload.status|tostring] | join(", ")' | sort --key=1 | awk '!a[$1]++' > 2020-01-31.2020-02-13.evss.claims-status.TRANSFORMED.csv
#
#sed -i '1iUSER_UUID,TIMESTAMP,REQUEST_UUID,PATH,STATUS' 2020-01-31.2020-02-13.evss.claims-status.TRANSFORMED.csv

#tar -czvf claims-status.tar.gz 2020-01-31.2020-02-13.evss.claims-status.TRANSFORMED.csv

require 'csv'

def generate_edipi_report
  input_filename = Dir.pwd + '/2020-01-31.2020-02-13.evss.claims-status.TRANSFORMED.csv'
  batch_size = 1000
  batch_count = 0
  report_filename = Dir.pwd + '/' + DateTime.now.strftime('%Y-%m-%d') + '_claims_inquiries_by_edipi_report.csv'

  File.open(report_filename, 'w') do |file|
    file << "EDIPI, IDME_UUID, TIMESTAMP\n"
  end

  results = ''
  table = CSV.table(input_filename)

  uuids = table[:user_uuid]
  times = table[:timestamp]

  puts "About to iterate over #{uuids.size} UUIDs... \n"
  uuids.zip(times).each_slice(batch_size) do |batch|
    puts "Batch size of request UUIDS is: " + batch.size.to_s
    puts "Batch looks like: " + batch.first.to_s

    results = Account.where(idme_uuid: batch.collect { |b| b[0] }).pluck(:edipi)
    puts "Found EDIPI results for " + results.size.to_s + " of " + batch.size.to_s + "total UUIDs in batch"

   output = batch.zip(results)

   CSV.open(report_filename, 'a+') do |csv|
     results.each { |result| csv << result.flatten }
   end

   batch_count = batch_count + 1
   puts "Done with batch #{batch_count} of #{Integer(batch_size/uuids.size)}... \n"
  end
end
## What actually ended up running the report:

def draft_generate_edipi_report
  input_filename = Dir.pwd + '/.csv'
  batch_size = 1000
  batch_count = 0
  report_filename = Dir.pwd + '/' + DateTime.now.strftime('%Y-%m-%d') + '_claims_inquiries_by_edipi_report.csv'

  File.open(report_filename, 'w') do |file|
    file << "EDIPI, IDME_UUID, TIMESTAMP\n"
  end

  results = ''
  table = CSV.table(input_filename)

  uuids = table[:user_uuid]
  times = table[:timestamps]

  # edipi = table[:edipi]
  puts "About to iterate over #{uuids.size} UUIDs... \n"
  uuids.zip(times).each_slice(batch_size) do |batch|
    results = Account.where(idme_uuid: batch.collect { |b| b[0] }).pluck(:edipi)
    puts "ERROR, results is only: " + results.size.to_s if results != batch.size

    batch.zip(results)

    CSV.open(report_filename, 'a+') do |csv|
      csv.push(results)
    end

    batch_count = batch_count + 1
    puts "Done with batch #{batch_count} of #{Integer(batch_size/uuids.size)}... \n"
  end
end
