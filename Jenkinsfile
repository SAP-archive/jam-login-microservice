/////////////////[ Pipeline Configuration ]//////////////////
def git_url = 'git@github.wdf.sap.corp:/Jam-clm/login_proxy.git'

def git_spec = [branch: BRANCH_NAME, credentialsId: 'github-clm', url: git_url]

def aws_base() { return '371089343861.dkr.ecr.us-west-1.amazonaws.com' }
def aws_repository() { return 'kora/kora_data' }

def local_registry() { return 'clm-registry.mo.sap.corp:5000' }
def local_images = [
  prod: 'clm-loginproxy-prod',
  test: 'clm-loginproxy-test',
  dev: 'clm-loginproxy-dev',
]

def container_prompts = [
  dev: 'loginproxy-dev',
  test: 'loginproxy-test',
  prod_prefix: 'loginproxy-'
]

def kubernetes = [
  deployment: 'deploy/loginproxy',
  pod_image: 'loginproxy'
]

def mail_recipients = 'DL SAP Jam CLM <DL_58AF12A15F99B7D3BC000054@exchange.sap.corp>'
/////////////////[ End Pipeline Configuration ]//////////////////
stage "Checkout"
node('docker') {
    step([$class:'WsCleanup'])
    git git_spec

    currentBuild.description = generate_tag()

    docker_image_cleanup()

    stash "lp-workspace"
}
stage "Build Images"
node('docker') {
    unstash "lp-workspace"

    docker_image_cleanup()

    dev_image_stable = local_repo_image(local_images.dev, stable_tag())
    test_image_stable = local_repo_image(local_images.test, stable_tag())
    prod_image_stable = local_repo_image(local_images.prod, stable_tag())

    dev_image = local_repo_image(local_images.dev, currentBuild.description)
    test_image = local_repo_image(local_images.test, currentBuild.description)
    prod_image = local_repo_image(local_images.prod, currentBuild.description)

    docker_pull(  dev_image_stable, true )
    docker_pull( test_image_stable, true )
    docker_pull( prod_image_stable, true )

    sh 'docker/jenkins-build.sh dev ' + dev_image + \
                              ' --prompt ' + container_prompts.dev + \
                              ' --build-info build=' + currentBuild.description
    sh 'docker/jenkins-build.sh test ' + test_image + \
                              ' --prompt ' + container_prompts.test + \
                              ' --build-info build=' + currentBuild.description
    sh 'docker/jenkins-build.sh prod ' + prod_image + \
                              ' --prompt ' + container_prompts.prod_prefix + currentBuild.description + \
                              ' --build-info build=' + currentBuild.description

    // never push latest, since this build hasn't been validated

    // these image names contain the build/git-sha qualified tags (ie, we're not pushing anything as stable)
    docker_push(  dev_image )
    docker_push( test_image )
    docker_push( prod_image )
}
stage "Test"
parallel(
    "test_elixir": {
        node('docker') {
            unstash "lp-workspace"
            docker_image_cleanup()

            test_image = local_repo_image(local_images.test, currentBuild.description)
            tag_spec = 'TAG=' + currentBuild.description + ' '

            docker_pull( test_image )
            docker_pull( 'redis:3.0' )

            sh('docker-compose -f docker/jenkins.yml down --remove-orphans')

            //
            // Prepare the environment (bring up db and run migrations)
            //
            sh(tag_spec + 'docker-compose -f docker/jenkins.yml up -d redis')
            sleep(10) // 10s
            sh('chmod a+w phoenix/test/reports phoenix/cover')

            //
            // Run the actual tests
            //
            try {

              sh(tag_spec + 'docker-compose -f docker/jenkins.yml run --rm service_test mix coveralls.html')

            } catch (any) {
              currentBuild.result = 'FAILURE'
              send_mail(mail_recipients)
              throw any //rethrow exception to prevent the build from proceeding
            } finally {
              sh(tag_spec + 'docker-compose -f docker/jenkins.yml down')
              generate_reports()
            }
        }
    },
    "test_api": {
        node('docker') {
            unstash "lp-workspace"
            docker_image_cleanup()

            api_test_image = local_repo_image('clm-api-testing', '')
            prod_image = local_repo_image(local_images.prod, currentBuild.description)
            tag_spec = 'TAG=' + currentBuild.description + ' '

            docker_pull( prod_image )
            docker_pull( 'redis:3.0' )
            docker_pull( api_test_image )

            sh('docker-compose -f docker/jenkins.yml down --remove-orphans')

            //
            // Prepare the environment (bring up db & prod instance)
            //
            sh(tag_spec + 'docker-compose -f docker/jenkins.yml up -d redis')
            sleep(10) // 10s
            sh(tag_spec + 'docker-compose -f docker/jenkins.yml up -d service_prod')
            sleep(10) // 10s
            sh('chmod a+w phoenix/test/reports phoenix/test/testcases')

            //
            // Run the actual tests: populate the db via api and then run the test runner
            //
            try {

              sh(tag_spec + 'docker-compose -f docker/jenkins.yml exec -T service_prod mix data.populate --api')

              sh(tag_spec + 'docker-compose -f docker/jenkins.yml run --rm api_test_runner')

            } catch (any) {
              currentBuild.result = 'FAILURE'
              send_mail(mail_recipients)
              throw any //rethrow exception to prevent the build from proceeding
            } finally {
              sh(tag_spec + 'docker-compose -f docker/jenkins.yml down')
              archive_xml_report()
            }
        }
    }
)
stage "Push tags"
node('docker') {
    unstash "lp-workspace"
    docker_image_cleanup()

    //
    // pull our build-specific images to the local machine
    //
    dev_image = local_repo_image(local_images.dev, currentBuild.description)
    test_image = local_repo_image(local_images.test, currentBuild.description)
    prod_image = local_repo_image(local_images.prod, currentBuild.description)

    docker_pull( dev_image )
    docker_pull( test_image )
    docker_pull( prod_image )

    //
    // since this particular build is a success, tag it as stable
    // then push to our local dev registry
    //
    dev_image_stable = local_repo_image(local_images.dev, stable_tag())
    test_image_stable = local_repo_image(local_images.test, stable_tag())
    prod_image_stable = local_repo_image(local_images.prod, stable_tag())

    docker_tag(  dev_image,  dev_image_stable )
    docker_tag( test_image, test_image_stable )
    docker_tag( prod_image, prod_image_stable )

    docker_push(  dev_image_stable )
    docker_push( test_image_stable )
    docker_push( prod_image_stable )

    //
    // finally, tag our images for pushing to aws (build-tagged & stable)
    // then login to aws & push the images up
    //
    aws_image = aws_repo_image(currentBuild.description)
    aws_image_stable = aws_repo_image(stable_tag())

    docker_tag( prod_image, aws_image )
    docker_tag( prod_image, aws_image_stable )

    // login to aws
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'aws-ec2-access',
      usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
      sh('$( aws ecr get-login --no-include-email --region us-west-1 )')
     }

    docker_push( aws_image )
    docker_push( aws_image_stable )
}
stage "Deploy Dev-AWS"
node('docker') {

  //
  // Assuming the previous step succeeded, we should have the successful docker image in aws already
  // Now we just use kubectl to update the yaml, specifying the new image should be used in the deployment
  //  it should automatically trigger a rolling update
  //
  aws_image = aws_repo_image(currentBuild.description)

  withCredentials([file(credentialsId: 'k8s-access', variable: 'KUBECONFIGFILE')]) {
    sh('kubectl --kubeconfig=$KUBECONFIGFILE -n kora-test set image ' + kubernetes.deployment + ' ' + kubernetes.pod_image + '=' + aws_image)
  }
  currentBuild.result = 'SUCCESS'
  send_mail(mail_recipients) // should only mail if we move from failure to success
}

//
// Reporting
//

def generate_reports() {
    archive_xml_report()
    // Displays coverage reports
    archive (includes: 'phoenix/cover/*.html')
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

def send_mail(mail_recipients) {
  step([$class: 'Mailer', notifyEveryUnstableBuild: true, recipients: mail_recipients, sendToIndividuals: true])
}


//
// Helper functions
//

//
// generate_tag (for tagging both build and docker image result)
//
// 12-fcc5e800
// 13-4e5a6be4-mybranch
// branch is only specified if it is not master
//
def generate_tag() {
    buildNumber = currentBuild.number
    gitCommit = sh(returnStdout: true, script: 'git rev-parse --short --verify HEAD').trim()
    branch = (BRANCH_NAME != "master") ? "-" + BRANCH_NAME : ""
    return buildNumber + '-' + gitCommit + branch
}
def stable_tag() {
    branch = (BRANCH_NAME != "master") ? "stable-" + BRANCH_NAME : "stable"
    return branch
}

//
// local_repo_image & aws_repo_image
//  (image name for the local image repository & aws)
// local takes the sub-image, (ie, dev/test/prod)
//
def local_repo_image(image_mode, tag) {
    if (tag == '') {
      return local_registry() + '/' + image_mode
    } else {
      return local_registry() + '/' + image_mode + ':' + tag
    }
}

def aws_repo_image(tag) {
    return aws_base() + '/' + aws_repository() + ':' + tag
}

// docker pull
def docker_pull(image, pass_if_image_missing = false) {
    sh 'docker pull ' + image + (pass_if_image_missing ? ' || true' : '')
}
def docker_push(image) {
    sh 'docker push ' + image
}
def docker_image_cleanup() {
    sh '(docker volume ls -qf dangling=true | xargs -r docker volume rm) || true'
    sh '(docker images --filter dangling=true | awk \'NR>1{ print $3 }\' | xargs -r docker rmi) || true'
}
def docker_tag(image1, image2) {
    sh('docker tag ' + image1 + ' ' + image2)
}
