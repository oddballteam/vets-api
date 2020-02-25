web: bundle exec puma -p 3000 -C ./config/puma.rb
job: BUNDLE_GEMFILE=Gemfile.worker bundle exec sidekiq -q default -q critical -q tasker
freshclam: /usr/bin/freshclam -d --config-file=config/freshclam.conf
clamd: /usr/sbin/clamd -c config/clamd.conf
