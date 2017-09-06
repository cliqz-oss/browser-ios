node('ios-osx') {
    stage("Checkout") {
        checkout scm

        withCredentials([file(credentialsId: 'ceb2d5e9-fc88-418f-aa65-ce0e0d2a7ea1', variable: 'CLIQZ_CI_SSH_KEY')]) {
            sh '''#!/bin/bash -l -x
                set -e
                set -x
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
            set -e
            set -x
            rvm use ruby-2.4.0
            gem install xcpretty -N
            gem install cocoapods
            brew update
            brew install xctool
            brew install carthage
            npm install -g yarn
            pod --version
        '''

        // load/restore carthage build directory
        sh '''#!/bin/bash -l
            set -e
            set -x
            CART_CACHE=/tmp/carthage_cache_`md5 -q Cartfile`.tar; tar -xf $CART_CACHE ; echo A |./bootstrap.sh && tar -cf $CART_CACHE Carthage Cartfile.resolved
        '''

        sh '''#!/bin/bash -l
            set -e
            set -x
            rm -R ./node_modules
            yarn
            pod install
            npm run bundle
        '''
    }
    try {
        stage('Build') {
            timeout(20) {
                sh '''#!/bin/bash -l
                    set -e
                    set -x
                    rvm use ruby-2.4.0
                    xcodebuild -workspace Client.xcworkspace -scheme "Fennec" -sdk iphonesimulator -destination "platform=iOS Simulator,OS=10.3.1,id=8F1A1F1B-4428-45F4-B282-DE628D9A54A1" ONLY_ACTIVE_ARCH=NO -derivedDataPath clean build test | xcpretty -tc && exit ${PIPESTATUS[0]}
                '''
            }
        }

        stage('Appium') {
            sh '''#!/bin/bash -l
                set -e
                set -x
                brew install node
                npm install -g appium
                npm install wd
                appium &
            '''
        }

        stage('Run Tests') {
            withEnv(['platformName=ios', 'udid=8F1A1F1B-4428-45F4-B282-DE628D9A54A1', 'deviceName=iPhone 6', 'platformVersion=10.3.1']) {
                timeout(20) {
                    sh '''#!/bin/bash -l
                        set -e
                        set -x
                        cd external/autobots
                        chmod 0755 requirements.txt
                        sudo -H pip install -r requirements.txt
                        python testRunner.py
                        ret=$?
                        if [ $ret -ne 0 ]; then
                            echo "Something Went Wrong."
                            exit 1
                        fi
                    '''
                }
            }
        }

        stage('Upload Results') {
            archiveArtifacts allowEmptyArchive: true, artifacts: 'external/autobots/*.log'

            junit "external/autobots/test-reports/*.xml"

            try {
                zip archive: true, dir: 'external/autobots/screenshots', glob: '', zipFile: 'external/autobots/screenshots.zip'
            } catch (e) {
                // no screenshots, no problem
            }
        }
    } finally {
        stage('Cleanup') {
            sh '''#!/bin/bash -l -x
                xcrun simctl uninstall booted cliqz.ios.CliqzBeta || true
                rm -rf JSEngine
                rm -rf external/autobots
            '''
        }
    }
}
