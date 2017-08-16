node('ios-osx') {
    ws('ios-browser') {
        stage("Checkout") {
            checkout scm 
        }
        
        stage('Prepare') {
            
            sh '''#!/bin/bash -l
                rvm use ruby-2.4.0
                gem install xcpretty -N
                gem install cocoapods
                brew update
                brew install xctool
                brew install carthage
                pod --version
                echo A |./bootstrap.sh 
            '''
        }
        
        stage('Build') {
            sh '''#!/bin/bash -l
                rvm use ruby-2.4.0
                xcodebuild -workspace Client.xcworkspace -scheme "Fennec" -sdk iphonesimulator -destination "platform=iOS Simulator,OS=9.3,id=ADEE0E24-A523-48C9-AC91-BFD8762FC2E2" ONLY_ACTIVE_ARCH=NO -derivedDataPath build clean test | xcpretty -tc && exit ${PIPESTATUS[0]}
            '''
        }

        stage('Appium') {
            sh '''#!/bin/bash -l
                cd external/auobots
                ls
                cd ../..
                brew install node
                npm install -g appium
                npm install wd
                appium &
            '''
        }

        stage('Run Tests') {
            sh '''#!/bin/bash -l 
                git submodule init
                git submodule update
                cd external/auobots
                git checkout development
                export platformName="ios"
                export udid="ADEE0E24-A523-48C9-AC91-BFD8762FC2E2"
                export deviceName="iPhone 6"
                export platformVersion="9.3"
                chmod 0755 requirements.txt
                sudo -H pip install -r requirements.txt
                python testRunner.py | true
            '''
        }

        stage('Upload Results') {
        step([
            $class: 'JUnitResultArchiver',
            allowEmptyResults: false,
            testResults: "test-reports/*.xml"
        ])
        }
    }
}
