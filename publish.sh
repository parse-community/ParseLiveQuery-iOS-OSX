#!/bin/sh -e
gem install bundler
bundle install
EXPANDED_CODE_SIGN_IDENTITY="-" EXPANDED_CODE_SIGN_IDENTITY_NAME="-" bundle exec pod trunk push ParseLiveQuery.podspec --allow-warnings
