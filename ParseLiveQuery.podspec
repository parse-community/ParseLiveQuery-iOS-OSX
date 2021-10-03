Pod::Spec.new do |s|
  s.name             = 'ParseLiveQuery'
  s.version          = '2.8.1'
  s.license          =  { :type => 'BSD' }
  s.summary          = 'Allows for subscriptions to queries in conjunction with parse-server.'
  s.homepage         = 'http://parseplatform.org'
  s.social_media_url = 'https://twitter.com/ParsePlatform'
  s.authors          = { 'Parse Community' => 'info@parseplatform.org', 'Richard Ross' => 'richardross@fb.com', 'Nikita Lutsenko' => 'nlutsenko@me.com', 'Florent Vilmart' => 'florent@flovilmart.com' }

  s.source       = { :git => 'https://github.com/ParsePlatform/ParseLiveQuery-iOS-OSX.git', :tag => s.version.to_s }

  s.requires_arc = true

  s.platform = :ios, :osx, :tvos, :watchos
  s.swift_version = '5.0'
  s.cocoapods_version = '>= 1.4'

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '2.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'Sources/ParseLiveQuery/**/*.{swift,h}'
  s.module_name = 'ParseLiveQuery'

  s.dependency 'Parse', '~> 1.19.0'
  s.dependency 'Bolts-Swift', '~> 1.5.0'
  s.dependency 'Starscream', '~> 4.0.4'

end
