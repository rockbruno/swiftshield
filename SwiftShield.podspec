Pod::Spec.new do |s|
  s.name = 'SwiftShield'
  s.module_name = 'SwiftShield'
  s.version = '3.4.1'
  s.license = { type: 'MIT', file: 'LICENSE' }
  s.summary = 'A tool that protects Swift iOS apps against class-dump attacks.'
  s.homepage = 'https://github.com/rockbruno/swiftshield'
  s.authors = { 'Bruno Rocha' => 'brunorochaesilva@gmail.com' }
  s.social_media_url = 'https://twitter.com/rockthebruno'
  s.source = { http: "https://github.com/rockbruno/swiftshield/releases/download/#{s.version}/swiftshield.zip" }
  s.preserve_paths = '*'
  s.exclude_files = '**/file.zip'
end