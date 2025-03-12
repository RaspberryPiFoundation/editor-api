web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate
worker: bundle exec good_job start --max-threads=8
