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
    }
}
