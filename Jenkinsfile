pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' // archive file is archive23
            }
        }  
      stage('UNIT tests - JUnit and Jacoco') {
            steps {
              sh "mvn test"
            }
            post {
              always {
                    junit 'target/surefire-reports/*.xml'
                    jacoco execPattern: 'target/jacoco.exec'
            }
        }  
      }     
      stage('Docker Build and Push') {
          steps {
              withDockerRegistry([credentialsId: 'Docker-hub', url: '']) {

                  sh '''
                      set -e

                      IMAGE=sitotest/numeric-app
                      TAG=${GIT_COMMIT}

                      echo "Building ${IMAGE}:${TAG}"

                      docker build -t ${IMAGE}:${TAG} .

                      docker push ${IMAGE}:${TAG}

                      docker tag ${IMAGE}:${TAG} ${IMAGE}:latest
                      docker push ${IMAGE}:latest
                  '''
                  } 
              }
          
        }  

    }
}