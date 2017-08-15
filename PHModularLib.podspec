
Pod::Spec.new do |s|
  s.name             = 'PHModularLib'
  s.version          = '0.1.5'
  s.summary          = '基础模块框架'

  s.description      = <<-DESC
                        基于PHBaseLib的Modular的使用 
                       DESC

  s.homepage         = 'https://github.com/xphaijj/PHModularLib.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xphaijj0305@126.com' => '2112787533@qq.com' }
  s.source           = { :git => 'https://github.com/xphaijj/PHModularLib.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'PHModularLib/Classes/{Base,Manager}/*.{h,m}'
  s.public_header_files = 'PHModularLib/Classes/{Base,Manager}/*.h'
	  
  s.subspec 'Login' do |sp|
    sp.source_files = 'PHModularLib/Classes/Login/*.{h,m}'
    sp.public_header_files = 'PHModularLib/Classes/Login/*.h'
    sp.dependency 'UMengUShare/UI'
    sp.dependency 'UMengUShare/Social/ReducedWeChat'
    sp.dependency 'UMengUShare/Plugin/IDFA'
  end
  
  s.subspec 'Log' do |sp|
    sp.source_files = 'PHModularLib/Classes/Log/*.{h,m}'
    sp.public_header_files = 'PHModularLib/Classes/Log/*.h'
  end
  
  s.subspec 'Map' do |sp|
    sp.source_files = 'PHModularLib/Classes/Map/*.{h,m}'
    sp.public_header_files = 'PHModularLib/Classes/Map/*.h'
    sp.vendored_frameworks = 'PHModularLib/Classes/Map/BaiduTraceSDK.framework'
    sp.dependency 'BaiduMapKit'
  end
  
#  s.subspec 'Push' do |sp|
#    sp.source_files = 'PHModularLib/Classes/Push/*.{h,m}'
#    sp.public_header_files = 'PHModularLib/Classes/Push/*.h'
#    sp.dependency 'JPush'
#  end
  
  s.subspec 'Upload' do |sp| 
    sp.source_files = 'PHModularLib/Classes/Upload/*.{h,m}'
    sp.public_header_files = 'PHModularLib/Classes/Upload/*.h'
    sp.dependency 'AliyunOSSiOS'
  end

  s.dependency 'PHBaseLib'
  
end
