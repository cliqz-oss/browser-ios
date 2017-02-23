# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
use_frameworks!

target 'Client' do

 # Your 'node_modules' directory is probably in the root of your project,
 # but if not, adjust the `:path` accordingly
 pod 'React', :path => './node_modules/react-native', :subspecs => [
 'Core',
 'RCTText',
 'RCTNetwork',
 'RCTWebSocket',
 # needed for debugging
 # Add any other subspecs you want to use in your project
 ]
pod 'RNFS', :path => './node_modules/react-native-fs'
end
