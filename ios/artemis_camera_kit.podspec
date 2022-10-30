#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint artemis_camera_kit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'artemis_camera_kit'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  s.dependency 'GoogleMLKit/BarcodeScanning'
  s.dependency 'GoogleMLKit/TextRecognition'
  s.dependency 'MTBBarcodeScanner'
#   s.dependency 'GoogleMLKit/BarcodeScanning', '3.2.0'

  s.static_framework = true
end
