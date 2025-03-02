Pod::Spec.new do |s|
  s.name             = 'h3'
  s.version          = '0.0.1'
  s.summary          = 'H3 Core library'
  s.description      = 'H3 Core library for the flutter_h3 plugin'
  s.homepage         = 'https://h3geo.org/'
  s.license          = { :type => 'Apache 2.0' }
  s.author           = { 'Uber' => 'https://github.com/uber/h3' }
  s.source           = { :http => 'https://github.com/uber/h3/archive/refs/tags/v4.2.0.tar.gz' }
  s.ios.vendored_libraries = 'Frameworks/libh3.a'
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = 'Classes/**/*'
  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => '${PODS_ROOT}/../../.symlinks/plugins/flutter_h3/ios/Frameworks',
    'LIBRARY_SEARCH_PATHS' => '${PODS_ROOT}/../../.symlinks/plugins/flutter_h3/ios/Frameworks'
  }
end 