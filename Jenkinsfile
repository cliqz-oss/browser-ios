node('ios-osx') {
    stage("Checkout") {
        checkout scm 
        withCredentials([file(credentialsId: 'ceb2d5e9-fc88-418f-aa65-ce0e0d2a7ea1', variable: 'CLIQZ_CI_SSH_KEY')]) {
            sh '''#!/bin/bash -l -x
            mkdir -p ~/.ssh
            cp $CLIQZ_CI_SSH_KEY ~/.ssh/id_rsa
            chmod 600 ~/.ssh/id_rsa
            echo $CLIQZ_CI_SSH_KEY
            ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
            git submodule update --init
            '''
        }
    }
    
    stage('Prepare') {
        
        sh '''#!/bin/bash -l -x
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
        timeout(20) {
            sh '''#!/bin/bash -l -x
                rvm use ruby-2.4.0
                xcodebuild -workspace Client.xcworkspace -scheme "Fennec" -sdk iphonesimulator -destination "platform=iOS Simulator,OS=9.3,id=ADEE0E24-A523-48C9-AC91-BFD8762FC2E2" ONLY_ACTIVE_ARCH=NO -derivedDataPath build clean test | xcpretty -tc && exit ${PIPESTATUS[0]}
            '''
        }
    }

    stage('Appium') {
        sh '''#!/bin/bash -l -x
            brew install node
            npm install -g appium
            npm install wd
            appium &
        '''
    }

    stage('Run Tests') {
        withEnv(['platformName=ios', 'udid=ADEE0E24-A523-48C9-AC91-BFD8762FC2E2', 'deviceName=iPhone 6', 'platformVersion=9.3']) {
            timeout(30) {
                sh '''#!/bin/bash -l -x
                    cd external/autobots
                    chmod 0755 requirements.txt
                    sudo -H pip install -r requirements.txt
                    python testRunner.py | true
                    xcrun simctl uninstall booted cliqz.ios.CliqzBeta
                '''
            }
        }
    }

    stage('Upload Results') {
        junit "external/autobots/test-reports/*.xml"
    }
}