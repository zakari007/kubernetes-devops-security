post {
    success {
        setGitHubStatus(
            'Jenkins build passed',
            'SUCCESS'
        )
    }

    failure {
        setGitHubStatus(
            'Jenkins build failed',
            'FAILURE'
        )
    }

    unstable {
        setGitHubStatus(
            'Jenkins build is unstable',
            'FAILURE'
        )
    }
}


pipeline {
    agent any

    stages {

        stage('Build Artifact') {
            steps {
                sh '''
                    set -e
                    echo "===== BUILD ARTIFACT ====="

                    mvn clean package -DskipTests=true
                '''

                archiveArtifacts artifacts: 'target/*.jar',
                                 fingerprint: true
            }
        }

        stage('UNIT Tests - JUnit and Jacoco') {
            steps {
                sh '''
                    set -e
                    echo "===== UNIT TESTS ====="

                    mvn test
                '''
            }

            post {
                always {
                    echo "===== JUNIT RESULTS ====="

                    junit(
                        testResults: 'target/surefire-reports/*.xml',
                        allowEmptyResults: false
                    )

                    echo "===== JACOCO RESULTS ====="

                    jacoco(
                        execPattern: 'target/jacoco.exec'
                    )
                }
            }
        }

        stage('Docker Build and Push') {
            steps {
                withDockerRegistry([
                    credentialsId: 'Docker-hub',
                    url: ''
                ]) {

                    sh '''
                        set -e

                        IMAGE=sitotest/numeric-app
                        TAG=${GIT_COMMIT}

                        echo "===== DOCKER BUILD ====="
                        echo "Image: ${IMAGE}:${TAG}"

                        docker build \
                            -t ${IMAGE}:${TAG} \
                            .

                        echo "===== DOCKER PUSH ====="

                        docker push ${IMAGE}:${TAG}

                        echo "===== DOCKER LATEST TAG ====="

                        docker tag \
                            ${IMAGE}:${TAG} \
                            ${IMAGE}:latest

                        docker push ${IMAGE}:latest

                        echo "Docker image successfully pushed:"
                        echo "${IMAGE}:${TAG}"
                        echo "${IMAGE}:latest"
                    '''
                }
            }
        }

        stage('Kubernetes Deployment') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo " KUBERNETES DEPLOYMENT"
                    echo "======================================"

                    echo "===== Kubernetes Cluster ====="
                    kubectl cluster-info

                    echo "===== Current Context ====="
                    kubectl config current-context

                    echo "===== Kubernetes Nodes ====="
                    kubectl get nodes

                    echo "===== Updating Image ====="

                    sed -i "s#replace#sitotest/numeric-app:${GIT_COMMIT}#g" \
                        k8s_deployment_service.yaml

                    echo "===== Kubernetes Manifest ====="
                    grep -n "image:" k8s_deployment_service.yaml

                    echo "===== Applying Deployment ====="

                    kubectl apply \
                        -f k8s_deployment_service.yaml

                    echo "===== Deployments ====="

                    kubectl get deployments

                    echo "===== Pods ====="

                    kubectl get pods -o wide

                    echo "===== Services ====="

                    kubectl get services

                    echo "===== Kubernetes Deployment Complete ====="
                '''
            }
        }
    }

    post {

        success {
            echo """
            ======================================
            JENKINS BUILD SUCCESS
            ======================================

            Job:       ${JOB_NAME}
            Build:     #${BUILD_NUMBER}
            Commit:    ${GIT_COMMIT}

            Jenkins:
            ${BUILD_URL}

            ======================================
            """
        }

        failure {
            echo """
            ======================================
            JENKINS BUILD FAILED
            ======================================

            Job:       ${JOB_NAME}
            Build:     #${BUILD_NUMBER}
            Commit:    ${GIT_COMMIT}

            Jenkins Console:
            ${BUILD_URL}console

            ======================================
            """
        }

        unstable {
            echo """
            ======================================
            JENKINS BUILD UNSTABLE
            ======================================

            Job:       ${JOB_NAME}
            Build:     #${BUILD_NUMBER}

            Jenkins:
            ${BUILD_URL}

            ======================================
            """
        }

        always {
            echo "Jenkins Build URL: ${BUILD_URL}"
        }
    }
}