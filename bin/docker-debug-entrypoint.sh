#!/bin/bash

rails db:prepare
rdbg -n -o -c -- bin/rails s -p 3009 -b '0.0.0.0'
