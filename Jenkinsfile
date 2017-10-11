node('ios-osx') {
    stage("Checkout") {
        checkout scm
        withCredentials([file(credentialsId: 'ceb2d5e9-fc88-418f-aa65-ce0e0d2a7ea1', variable: 'CLIQZ_CI_SSH_KEY')]) {
            sh '''#!/bin/bash -l
            set -x
            set -e
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

        sh '''#!/bin/bash -l
            set -x
            set -e
            rvm use ruby-2.4.0
            gem install xcpretty -N
            gem install cocoapods
            brew update
            brew list xctool &>/dev/null || brew install xctool
            brew list carthage &>/dev/null || brew install carthage
            npm install -g yarn
            pod --version
        '''
        // load/restore carthage build directory
        sh '''#!/bin/bash -l
            set -x
            CART_CACHE=/tmp/carthage_cache_`md5 -q Cartfile`.tar; tar -xf $CART_CACHE ; echo A |./bootstrap.sh && tar -cf $CART_CACHE Carthage Cartfile.resolved
        '''
        sh '''#!/bin/bash -l
            set -x
            set -e
            rm -rf ./node_modules
            yarn
            pod install
            npm run bundle
        '''
    }
    try {
        stage('Build') {
            timeout(20) {
                sh '''#!/bin/bash -l
                    set -x
                    set -e
                    rvm use ruby-2.4.0
                    xcodebuild -workspace Client.xcworkspace -scheme "Fennec" -sdk iphonesimulator -destination "platform=iOS Simulator,OS=11.0,id=16404244-D9D7-48BC-B160-E275E9E53239" ONLY_ACTIVE_ARCH=NO -derivedDataPath clean build test | xcpretty -tc && exit ${PIPESTATUS[0]}
                '''
            }
        }

        stage('Appium') {
            sh '''#!/bin/bash -l
                set -x
                set -e
                brew list node &>/dev/null || brew install node
                npm install -g appium
                npm install -g wd
                appium &
                echo $! > appium.pid
            '''
        }

        stage('Run Tests') {
            withEnv(['platformName=ios', 'udid=16404244-D9D7-48BC-B160-E275E9E53239', 'deviceName=iPhone 6', 'platformVersion=11.0']) {
                timeout(45) {
                    sh '''#!/bin/bash -l
                        set -x
                        set -e
                        cd external/autobots
                        chmod 0755 requirements.txt
                        sudo -H pip install -r requirements.txt
                        sleep 10
                        python testRunner.py
                    '''
                }
            }
        }
    }
    finally {
        stage('Upload Results') {
            try {
                archiveArtifacts allowEmptyArchive: true, artifacts: 'external/autobots/*.log'
                junit "external/autobots/test-reports/*.xml"
                zip archive: true, dir: 'external/autobots/screenshots', glob: '', zipFile: 'external/autobots/screenshots.zip'
            } catch (e) {
                // no screenshots, no problem
            }
        }
        stage('Cleanup') {
            sh '''#!/bin/bash -l
                set -x
                set -e
                kill `cat appium.pid` || true
                rm -f appium.pid
                xcrun simctl uninstall booted cliqz.ios.CliqzBeta || true
                xcrun simctl uninstall booted com.apple.test.WebDriverAgentRunner-Runner || true
                xcrun simctl uninstall booted com.apple.test.AppiumTests-Runner || true
                rm -rf JSEngine
                rm -rf external/autobots
                npm uninstall -g appium
                npm uninstall -g wd
            '''
        }
    }
}
