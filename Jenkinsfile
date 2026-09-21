pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' // archive file is archive23
            }
        }  
      stage('UNIT tests') {
            steps {
              sh "mvn test"
            }
        }  

    }
}