#
# Be sure to run `pod lib lint MaterialTabBar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MaterialTabBar'
  s.version          = '0.2.1'
  s.summary          = 'A tab bar controller based on Material design.'

  s.description      = <<-DESC
Simple and customizable tab bar controller which resembles the Material tab bar on Android.
                       DESC

  s.homepage         = 'https://github.com/haluzak/MaterialTabBar'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Michal Rentka' => 'michalrentka@gmail.com' }
  s.source           = { :git => 'https://github.com/haluzak/MaterialTabBar.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'MaterialTabBar/Classes/**/*'
end
