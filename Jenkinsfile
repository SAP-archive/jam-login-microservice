// Configuration
// code branch
def branch_us = BRANCH_NAME


// Git branches & credentials
def creds = 'github-clm'

def url_us = 'git@github.wdf.sap.corp:/Jam-clm/login_proxy.git'

def git_us = [branch: branch_us, credentialsId: creds, poll: false, url: url_us]


stage "Checkout"
node('docker') {
    docker_image_cleanup()
    step([$class:'WsCleanup'])
    git git_us
    gitCommit = sh(returnStdout: true, script: 'git rev-parse --short --verify HEAD').trim()
    branch_desc = ""
    if(BRANCH_NAME != "master") {
        branch_desc = "-" + BRANCH_NAME
    }
    currentBuild.description = currentBuild.number + '-' + gitCommit + branch_desc
    stash "us-workspace"
}
stage "Build Images"
node('docker') {
    unstash "us-workspace"

    docker_image_cleanup()
    sh 'docker pull clm-registry.mo.sap.corp:5000/clm-loginproxy-test || true'
    sh 'docker pull clm-registry.mo.sap.corp:5000/clm-loginproxy-prod || true'

    sh 'docker/build.sh --test --prod'
    sh 'docker push clm-registry.mo.sap.corp:5000/clm-loginproxy-test'
    sh 'docker push clm-registry.mo.sap.corp:5000/clm-loginproxy-prod'
    stash "us-workspace" 
}
stage "Test"
parallel(
    "test_elixir": {
        node('docker') {
            unstash "us-workspace"
            docker_image_cleanup()
            sh 'docker pull clm-registry.mo.sap.corp:5000/clm-loginproxy-test'

            sh 'docker pull redis:3.0'
            // sh 'docker pull sjc-registry.itc.sap.com/sjc-redis'
            // sh 'docker pull sjc-registry.itc.sap.com/sjc-sentinel'

            try {
                sh 'mkdir -p phoenix/cover && \
                chmod go+w phoenix/test/reports phoenix/cover && \
                cd docker && \
                docker-compose down && \
                docker-compose up -d redis && \
                sleep 10 && \
                docker-compose run login_proxy_test mix coveralls.html && \
                docker-compose down'
            } catch(err) {
              generate_reports()
              throw err
            }
            generate_reports()
        }
    },
    "test_api": {
        node('docker') {
            unstash "us-workspace"
            docker_image_cleanup()
            sh 'docker pull clm-registry.mo.sap.corp:5000/clm-loginproxy-prod'
            sh 'docker pull mongo:3.0'
            sh 'docker pull clm-registry.mo.sap.corp:5000/clm-api-testing'


            try {
                sh 'chmod go+w phoenix/test/reports phoenix/test/testcases && \
                cd docker && \
                docker-compose -f docker-compose-api.yml down && \
                docker-compose -f docker-compose-api.yml up -d redis && \
                sleep 10 && \
                docker-compose -f docker-compose-api.yml up -d service_prod && \
                sleep 10 && \
                docker-compose -f docker-compose-api.yml exec -T service_prod mix data.populate && \
                docker-compose -f docker-compose-api.yml run api_test_runner && \
                docker-compose -f docker-compose-api.yml down'
            } catch(err) {
              archive_xml_report()
              throw err
            }
            archive_xml_report()
        }
    }
)
stage "Push tags"
node('docker') {
    unstash "us-workspace"
    docker_image_cleanup()
    // sh 'docker pull sjc-registry.itc.sap.com/sjc-tm'
    // sh 'tag="$(cat build_sha.txt)" && docker tag sjc-registry.itc.sap.com/sjc-tm sjc-registry.itc.sap.com/sjc-tm:$tag && docker push sjc-registry.itc.sap.com/sjc-tm:$tag'
    // sh 'tag="$(cat build_tags.txt)" && if [ "${#tag}" != "0" ]; then docker tag sjc-registry.itc.sap.com/sjc-tm sjc-registry.itc.sap.com/sjc-tm:$tag && docker push sjc-registry.itc.sap.com/sjc-tm:$tag; fi'
}

def docker_image_cleanup() {
    sh '(docker volume ls -qf dangling=true | xargs docker volume rm) || true'
    sh '(docker images --filter dangling=true | awk \'NR>1{ print $3 }\' | xargs -r docker rmi) || true'
}

def generate_reports() {
    archive_xml_report()
    // Displays coverage reports
    archive (includes: 'phoenix/cover/*')
    publishHTML (target: [
      allowMissing: false,
      keepAll: false,
      reportDir: 'phoenix/cover',
      reportFiles: 'excoveralls.html',
      reportName: "Coverage Report"
    ])
}

def archive_xml_report() {
    // Displays xml test report
    step([$class: 'JUnitResultArchiver', testResults: 'phoenix/test/reports/*.xml'])
}

