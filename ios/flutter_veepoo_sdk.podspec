#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_veepoo_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_veepoo_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Veepoo SDK Smartwatch for Flutter.'
  s.description      = <<-DESC
Veepoo SDK Smartwatch for Flutter.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Vendor SDK (HBandSDK/iOS_Ble_SDK): VeepooBleSDK 2.2.XX.15 + the frameworks its demo app links.
  # VeepooBleSDK is a static archive whose swiftinterface was built with Swift 6.2.3 (needs Xcode 26.2+).
  # Every vendor binary is arm64 device-only (no simulator slice): build and run on a real iPhone.
  s.vendored_frameworks = 'Frameworks/*.framework'
  s.dependency 'FMDB'
  s.dependency 'MJExtension'
  s.frameworks = 'CoreBluetooth', 'CoreLocation'
  s.static_framework = true
  # The vendor demo links with -ObjC; the static SDK relies on ObjC categories being loaded.
  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '$(inherited) -ObjC' }

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_veepoo_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
