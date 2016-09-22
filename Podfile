use_frameworks!
workspace 'ParseLiveQuery.xcworkspace'

def commonPods
  pod 'Parse'
  pod 'Bolts-Swift', :git => 'https://github.com/BoltsFramework/Bolts-Swift.git', tag: '1.3.0'
  pod 'SocketRocket'
end

post_install do |installer|
  # Force Swift version for Xcode 8
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
	end
end

target 'ParseLiveQuery-OSX' do
  project 'Sources/ParseLiveQuery.xcodeproj'
  platform :osx, '10.10'

  commonPods
end

target 'ParseLiveQuery-iOS' do
  project 'Sources/ParseLiveQuery.xcodeproj'
  platform :ios, '8.0'

  commonPods
end

target 'LiveQueryDemo' do
  project 'Examples/LiveQueryDemo.xcodeproj'
  platform :osx, '10.10'

  commonPods
end

target 'LiveQueryDemo-ObjC' do
  project 'Examples/LiveQueryDemo-ObjC.xcodeproj'
  platform :osx, '10.10'

  commonPods
end
