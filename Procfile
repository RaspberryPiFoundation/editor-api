web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate:with_data projects:create_starter
worker: bundle exec good_job start --max-threads=8
