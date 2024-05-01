rails db:prepare --trace
rails projects:create_all
rdbg -n --open -c -- bin/rails s -p 3009 -b '0.0.0.0'
