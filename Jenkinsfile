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
              sh 'printenv'
              sh 'docker build -t sitotest/numeric-app:""$GIT_COMMIT"" .'
              sh 'docker push sitotest/numeric-app:""$GIT_COMMIT""' 
            }
        }  

    }
}