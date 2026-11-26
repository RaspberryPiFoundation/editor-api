web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate && bundle exec rake integration_tests:dispatch
worker: DB_POOL=${WORKER_DB_POOL:-25} bundle exec good_job start --max-threads=8
