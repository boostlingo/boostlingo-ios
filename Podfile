source 'https://github.com/CocoaPods/Specs.git'

target 'BoostlingoQuickstart' do
  platform :ios, '12.2'
  use_frameworks!

  # Release
  pod 'BoostlingoSDK', '1.0.1'

  # Local
  # pod 'BoostlingoSDK', :path => '../boostlingo-sdk-ios-src/build/BoostlingoSDK.podspec'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
