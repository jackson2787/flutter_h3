#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_h3.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_h3'
  s.version          = '0.0.1'
  s.summary          = 'Flutter bindings for Uber H3 library.'
  s.description      = <<-DESC
Flutter plugin providing bindings to the Uber H3 geospatial indexing system.
                       DESC
  s.homepage         = 'https://github.com/yourusername/flutter_h3'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  
  # Include the H3 library headers and static library
  s.vendored_libraries = 'Frameworks/libh3.a'
  s.preserve_paths = 'Frameworks/h3api.h', 'Frameworks/libh3.a'
  
  # Make sure the header is available - using a proper relative path
  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => '${PODS_ROOT}/../.symlinks/plugins/flutter_h3/ios/Frameworks',
    'LIBRARY_SEARCH_PATHS' => '${PODS_ROOT}/../.symlinks/plugins/flutter_h3/ios/Frameworks',
    'OTHER_LDFLAGS' => '-force_load ${PODS_ROOT}/../.symlinks/plugins/flutter_h3/ios/Frameworks/libh3.a'
  }

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_h3_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
