Pod::Spec.new do |s|
  s.name        = "Swifter"
  s.version     = "1.0"
  s.summary     = "Tiny http server engine written in Swift programming language"
  s.homepage    = "https://github.com/glock45/swifter"
  s.license     = { :type => "BSD" }
  s.authors     = { "glock45" => "damian.kolakowski@up-next.com" }

  s.osx.deployment_target = "10.9"
  s.ios.deployment_target = "8.0"
  # s.source   = { :git => "https://github.com/glock45/swifter.git" }
  s.source_files = [ "Common/*.swift" ]
end
