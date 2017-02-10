Pod::Spec.new do |s|
  s.name = 'SwiftShield'
  s.module_name = 'SwiftShield'
  s.version = '0.9.3'
  s.license = { type: 'MIT', file: 'LICENSE' }
  s.summary = 'A tool that protects Swift iOS apps against class-dump attacks.'
  s.homepage = 'https://github.com/rockbruno/swiftshield'
  s.authors = { 'Bruno Rocha' => 'bruno.rocha@movile.com' }
  s.source = { :git => 'https://github.com/rockbruno/swiftshield.git', :tag => "#{s.version}" }
  s.ios.deployment_target = '7.0'
  s.source_files = 'bin/*'
end