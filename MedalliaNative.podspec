Pod::Spec.new do |s|
  s.name         = "MedalliaNative"
  s.version      = "0.1.0"
  s.summary      = "Pure native Medallia feedback module for React Native"
  s.license      = { :type => "MIT" }
  s.authors      = { "Your Name" => "you@example.com" }
  s.homepage     = "https://github.com/ahmedhango/NativeMedallia"
  s.source       = { :git => "https://github.com/ahmedhango/NativeMedallia.git", :tag => s.version.to_s }

  s.platforms    = { :ios => "12.0" }
  s.source_files = ["ios/**/*.{h,m,mm}"]

  s.dependency "React-Core"
end


