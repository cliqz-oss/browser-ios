# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
use_frameworks!

def project_pods
    react_path = './JSEngine/node_modules/react-native'
    yoga_path = File.join(react_path, 'ReactCommon/yoga')
    
    pod 'React', :path => './JSEngine/node_modules/react-native', :subspecs => [
    'Core',
    'RCTText',
    'RCTNetwork',
    'RCTWebSocket',
    # needed for debugging
    # Add any other subspecs you want to use in your project
    ]
    pod 'Yoga', :path => yoga_path
    pod 'RNFS', :path => './JSEngine/node_modules/react-native-fs'
    pod 'react-native-webrtc', :path => './JSEngine/node_modules/react-native-webrtc'
    pod 'RNDeviceInfo', :path => './JSEngine/node_modules/react-native-device-info'
end

target 'Client' do
    project_pods
end

target 'CliqzUITests' do
    project_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
