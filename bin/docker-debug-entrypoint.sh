rails db:prepare --trace
rails db:seed --trace
rdbg -n -o -c -- bin/rails s -p 3009 -b '0.0.0.0'
