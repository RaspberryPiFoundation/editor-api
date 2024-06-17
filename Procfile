web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate && bundle exec rails db:seed && bundle exec rake projects:create_all
worker: bundle exec good_job start --max-threads=8
