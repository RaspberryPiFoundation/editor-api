#!/bin/bash

rails db:prepare
rails server --port 3009 --binding 0.0.0.0
