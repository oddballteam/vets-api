# frozen_string_literal: true

require 'active_support/notifications'
require 'pry'
ActiveSupport::Notifications.subscribe('request.faraday') do |name, start_time, end_time, _, env|
  url = env[:url]
  http_method = env[:method].to_s.upcase
  duration = end_time - start_time
  StatsD.measure('api.external.request.duration', duration, tags: ["host:#{url.host}"])
  # $stderr.puts '[%s] %s %s (%.3f s)' % [url.host, http_method, url.request_uri, duration]
end
