node {
  stage('Checkout') {
    cleanWs()
    sh 'git lfs install'
    checkout scm
  }

  String version = '7.2' // platform version
  String project = 'project-name' // e.g. "customer-name"
  String registry = 'harbor.delivery.iqgeo.cloud'

  def shortCommit = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
  String buildTag = (new Date()).format('yyyyMMdd').concat("-${shortCommit}")

  stage ('Build: Build Image') {
    String name = "${registry}/${project}/platform-build"
    String options = "-f ./deployment/dockerfile.build --pull ."

    buildImage = docker.build(name,  options)

    docker.withRegistry("https://${registry}/", 'harbor-jenkins') {
      buildImage.push("latest") // not recommended but necessary w/o local caching
      buildImage.push("${version}")
      buildImage.push("${version}-${buildTag}")
    }
  }

  stage('Build: Appserver - Build & Push Docker Image') {
    String name = "${registry}/${project}/platform-appserver"
    String options = '-f ./deployment/dockerfile.appserver --pull deployment/'

    appserverImage = docker.build(name, options)

    docker.withRegistry("https://${registry}/", 'harbor-jenkins') {
      // appserverImage.push("latest") // not recommended
      appserverImage.push("${version}")
      appserverImage.push("${version}-${buildTag}")
    }
  }

  stage('Tools - Build Docker Image') {
    String name = "${registry}/${project}/platform-tools"
    String options = '-f ./deployment/dockerfile.tools --pull .'

    toolsImage = docker.build(name, options)

    docker.withRegistry("https://${registry}/", 'harbor-jenkins') {
      // toolsImage.push('latest') // not recommended
      toolsImage.push("${version}")
      toolsImage.push("${version}-${buildTag}")
    }
  }

  stage('Cleanup workspace') { cleanWs() }
}
