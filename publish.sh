#!/bin/sh -e
rvm use $(< .ruby-version) --install --binary --fuzzy
gem install bundler
bundle install
bundle exec pod trunk push ParseLiveQuery.podspec --allow-warnings
