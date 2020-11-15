ver=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Sources/ParseLiveQuery/Info.plist`
bundle exec jazzy \
--clean \
--author "Parse Community" \
--author_url http://parseplatform.org \
--github_url https://github.com/parse-community/ParseLiveQuery-iOS-OSX \
--root-url http://parseplatform.org/ParseLiveQuery-iOS-OSX/ \
--module-version ${ver} \
--theme fullwidth \
--skip-undocumented \
--output docs/api \
--module ParseLiveQuery \
--build-tool-arguments -scheme,ParseLiveQuery-iOS \
