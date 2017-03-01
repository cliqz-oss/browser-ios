# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
use_frameworks!

target 'Client' do

 react_path = './node_modules/react-native'
 yoga_path = File.join(react_path, 'ReactCommon/yoga')

 pod 'React', :path => './node_modules/react-native', :subspecs => [
 'Core',
 'RCTText',
 'RCTNetwork',
 'RCTWebSocket',
 # needed for debugging
 # Add any other subspecs you want to use in your project
 ]
 pod 'Yoga', :path => yoga_path
 pod 'RNFS', :path => './node_modules/react-native-fs'
end
