Pod::Spec.new do |s|

  s.name                  = 'NMSDK'
  s.version               = '0.3'
  s.summary               = 'nearit.com iOS SDK'
  s.description           = 'nearit.com iOS SDK, which can be extended with plugins'

  s.homepage              = 'https://github.com/nearit/nm.sdk'
  s.license               = 'MIT'

  s.author                = { 'Francesco Colleoni' => 'francesco@nearit.com' }
  s.source                = { :git => "https://github.com/nearit/nm.sdk.git", :tag => s.version.to_s }

  s.source_files          = 'NMSDK', 'NMSDK/**/*.{h,m,swift}'
  s.ios.deployment_target = '8.0'
  s.requires_arc          = true

  s.dependency              'NMPlug', '~> 0.5'
  s.dependency              'NMNet', '~> 0.1'
  s.dependency              'JWTDecode', '~> 1.0'

end
