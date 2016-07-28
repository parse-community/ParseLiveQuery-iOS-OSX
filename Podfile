# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
use_frameworks!
workspace 'ParseLiveQuery.xcworkspace'

def commonPods
    pod 'Parse', '~> 1.14.0'
    pod 'Bolts-Swift', '~> 1.1.0'
    pod 'SocketRocket', '~> 0.5.0'
end

target 'ParseLiveQuery-OSX' do
  project 'Sources/ParseLiveQuery.xcodeproj'
  platform :osx, '10.9'
  commonPods
end

target 'ParseLiveQuery-iOS' do
  project 'Sources/ParseLiveQuery.xcodeproj'
  platform :ios, '8.0'
  commonPods
end

target 'LiveQueryDemo' do
  project 'Examples/LiveQueryDemo.xcodeproj'
  platform :osx, '10.9'
  commonPods
end

target 'LiveQueryDemo-ObjC' do
  project 'Examples/LiveQueryDemo-ObjC.xcodeproj'
  platform :osx, '10.9'
  commonPods
end
