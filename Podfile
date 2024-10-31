target 'BoostlingoQuickstart' do
  platform :ios, '13.4'
  use_frameworks!

  pod 'BoostlingoSDK', '1.0.5'
  # pod 'BoostlingoSDK', :path => '../build/BoostlingoSDK.podspec'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'

      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.4'

      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
    end
  end
end
