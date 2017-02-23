Pod::Spec.new do |s|
  s.name             = 'ParseLiveQuery'
  s.version          = '1.1.0'
  s.license          =  { :type => 'BSD' }
  s.summary          = 'Allows for subscriptions to queries in conjunction with parse-server.'
  s.homepage         = 'https://github.com/ParsePlatform/parse-server'
  s.authors          = { 'Richard Ross' => 'richardross@fb.com', 'Nikita Lutsenko' => 'nlutsenko@me.com' }
  
  s.source       = { :git => 'https://github.com/ParsePlatform/ParseLiveQuery-iOS-OSX.git', :tag => s.version.to_s }

  s.requires_arc = true

  s.platform = :ios, :osx, :tvos

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  
  s.source_files = 'Sources/ParseLiveQuery/**/*.{swift,h}'
  s.module_name = 'ParseLiveQuery'
  
  s.dependency 'Parse', '~> 1.14.2'
  s.dependency 'Bolts-Swift', '~> 1.3'
  s.dependency 'Starscream', '2.0.3'
end
