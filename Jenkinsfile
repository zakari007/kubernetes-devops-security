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
      
      /**
      stage('Kubrnetes Deployment') {
          steps {
                  sh "sed -i 's#replace#sitotest/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                  sh "kubectl apply -f k8s_deployment_service.yaml"    
          }
      }
       **/
       /**
      stage('Kubernetes Test') {
          steps {
              sh '''
                  echo "===== HOST ====="
                  hostname
                  whoami
                  pwd

                  echo "===== KUBECTL ====="
                  which kubectl
                  kubectl version --client

                  echo "===== KUBECONFIG BEFORE ====="
                  echo "KUBECONFIG=$KUBECONFIG"

                  echo "===== NETWORK TEST ====="
                  curl -k https://192.168.10.51:6443/version

                  echo "===== KUBECTL WITHOUT CREDENTIAL ====="
                  kubectl cluster-info
              '''

              withKubeConfig([credentialsId: 'kubeconfig']) {
                  sh '''
                      echo "===== KUBECONFIG FROM JENKINS ====="
                      echo "KUBECONFIG=$KUBECONFIG"

                      echo "===== CONFIG ====="
                      kubectl config view --minify

                      echo "===== CONTEXT ====="
                      kubectl config current-context

                      echo "===== CLUSTER ====="
                      kubectl cluster-info

                      echo "===== NODES ====="
                      kubectl get nodes
                  '''
              }
          }
      }
      **/
      
      stage('Kubernetes Deployment') {
          steps {
              sh '''
                  set -e

                  echo "Kubernetes cluster:"
                  kubectl cluster-info

                  echo "Updating image:"
                  sed -i "s#replace#sitotest/numeric-app:${GIT_COMMIT}#g" \
                      k8s_deployment_service.yaml

                  echo "Applying deployment:"
                  kubectl apply -f k8s_deployment_service.yaml

                  echo "Deployment status:"
                  kubectl get deployments

                  echo "Pods:"
                  kubectl get pods
              '''
          }
        }
    }
}