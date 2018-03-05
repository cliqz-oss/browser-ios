#!/bin/env groovy

@Library('cliqz-shared-library@vagrant') _

node('mac-mini-ios') {
    writeFile file: 'Vagrantfile', text: '''
    Vagrant.configure("2") do |config|
        config.vm.box = "ios-xcode9.0.1"
        
        config.vm.define "prios" do |prios|
            prios.vm.hostname ="prios"
            
            prios.vm.network "public_network", :bridge => "en0", auto_config: false
            prios.vm.boot_timeout = 900
            prios.vm.provider "vmware_fusion" do |v|
                v.name = "prios"
                v.whitelist_verified = true
                v.gui = false
                v.memory = ENV["NODE_MEMORY"]
                v.cpus = ENV["NODE_CPU_COUNT"]
                v.cpu_mode = "host-passthrough"
                v.vmx["remotedisplay.vnc.enabled"] = "TRUE"
                v.vmx["RemoteDisplay.vnc.port"] = ENV["NODE_VNC_PORT"]
                v.vmx["ethernet0.pcislotnumber"] = "33"
            end
            prios.vm.provision "shell", privileged: false, run: "always", inline: <<-SHELL#!/bin/bash -l
                set -e
                set -x
                rm -f agent.jar
                curl -LO #{ENV['JENKINS_URL']}/jnlpJars/agent.jar
                ls .
                java -version
                nohup java -jar agent.jar -jnlpUrl #{ENV['JENKINS_URL']}/computer/#{ENV['NODE_ID']}/slave-agent.jnlp -secret #{ENV["NODE_SECRET"]} &
            SHELL
        end
    end
    '''

    vagrant.inside(
        'Vagrantfile',
        '/jenkins',
        4, // CPU
        8000, // MEMORY
        12000, // VNC port
        false, // rebuild image
    ) { 
        nodeId ->
        node(nodeId) {
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
                    set -e
                    set -x
                    java -version
                    node -v
                    npm -v
                    yarn -v
                    xcodebuild -version
                    pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
                    sudo xcodebuild -license accept
                    brew -v
                    npm -g install yarn
                    rm -rf Cartfile.resolved
                    carthage bootstrap --verbose --platform ios --color auto --no-use-binaries
                    yarn install
                    pod install
                    npm run bundle
                '''
            }
            try {
                stage('Build') {
                    timeout(60) {
                        sh '''#!/bin/bash -l
                            set -x
                            set -e
                            xcrun simctl list
                            xcodebuild -workspace Client.xcworkspace -scheme "Fennec" -sdk iphonesimulator -destination "platform=iOS Simulator,OS=11.0,id=28CAC526-4AE4-4559-9023-1429B5C94A79" ONLY_ACTIVE_ARCH=NO -derivedDataPath clean build test | xcpretty -tc && exit ${PIPESTATUS[0]}
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
                    '''
                }

                stage('Run Tests') {
                    withEnv(['platformName=ios', 'udid=28CAC526-4AE4-4559-9023-1429B5C94A79', 'deviceName=iPhone 6', 'platformVersion=11.0']) {
                        timeout(60) {
                            sh '''#!/bin/bash -l
                                set -x
                                set -e
                                cd external/autobots
                                chmod 0755 requirements.txt
                                python --version
                                sudo -H python -m ensurepip
                                sudo -H pip install --upgrade pip
                                sudo -H pip install -r requirements.txt
                                appium &
                                echo $! > appium.pid
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
    }
}
