Pod::Spec.new do |s|
  s.name             = 'UniRateAPI'
  s.version          = '0.1.1'
  s.summary          = 'Swift client for the UniRate API — real-time & historical currency exchange rates plus VAT.'

  s.description      = <<-DESC
    Official Swift client for the UniRate API. Fetch real-time and historical
    exchange rates across 170+ fiat and crypto currencies, convert amounts,
    list supported currencies, and look up VAT rates — all with async/await,
    Sendable, and Codable. Zero external dependencies (pure Foundation).
  DESC

  s.homepage         = 'https://github.com/UniRate-API/unirate-api-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'UniRate' => 'support@unirateapi.com' }
  s.source           = { :git => 'https://github.com/UniRate-API/unirate-api-swift.git', :tag => "v#{s.version}" }

  s.swift_versions   = ['5.9']

  s.ios.deployment_target     = '15.0'
  s.osx.deployment_target     = '12.0'
  s.tvos.deployment_target    = '15.0'
  s.watchos.deployment_target = '8.0'

  s.source_files     = 'Sources/UniRateAPI/**/*.swift'
  s.frameworks       = 'Foundation'
end
