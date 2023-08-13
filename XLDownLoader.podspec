Pod::Spec.new do |spec|

  spec.name         = "XLDownLoader"
  spec.version      = "1.0.0"
  spec.summary      = "Thread Safe IOS Universal Downloader"
  spec.homepage     = "https://github.com/hlc0000/XLDownLoader"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.platform     = :ios, "10.0"

  spec.source       = { :git => "https://github.com/hlc0000/XLDownLoader", :tag => "#{spec.version}" }

  spec.source_files  = "DownLoader/XLDownLoader/**/*.{h,m}"

end
