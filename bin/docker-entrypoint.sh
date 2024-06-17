rails db:prepare --trace
rails projects:create_all
rails server --port 3009 --binding 0.0.0.0
