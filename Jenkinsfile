def setGitHubStatus(String message, String state) {
    step([
        $class: 'GitHubCommitStatusSetter',

        reposSource: [
            $class: 'ManuallyEnteredRepositorySource',
            url: 'https://github.com/zakari007/kubernetes-devops-security'
        ],

        commitShaSource: [
            $class: 'BuildDataRevisionShaSource'
        ],

        contextSource: [
            $class: 'ManuallyEnteredCommitContextSource',
            context: 'continuous-integration/jenkins'
        ],

        statusResultSource: [
            $class: 'ConditionalStatusResultSource',
            results: [
                [
                    $class: 'AnyBuildResult',
                    message: message,
                    state: state
                ]
            ]
        ]
    ])
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

                archiveArtifacts(
                    artifacts: 'target/*.jar',
                    fingerprint: true
                )
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
                    junit(
                        testResults: 'target/surefire-reports/*.xml',
                        allowEmptyResults: false
                    )

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

                        docker build \
                            -t ${IMAGE}:${TAG} \
                            .

                        echo "===== DOCKER PUSH ====="

                        docker push ${IMAGE}:${TAG}

                        docker tag \
                            ${IMAGE}:${TAG} \
                            ${IMAGE}:latest

                        docker push ${IMAGE}:latest
                    '''
                }
            }
        }

        stage('Kubernetes Deployment') {
            steps {

                sh '''
                    set -e

                    echo "===== KUBERNETES CLUSTER ====="

                    kubectl cluster-info

                    echo "===== KUBERNETES NODES ====="

                    kubectl get nodes

                    echo "===== UPDATE IMAGE ====="

                    sed -i "s#replace#sitotest/numeric-app:${GIT_COMMIT}#g" \
                        k8s_deployment_service.yaml

                    echo "===== APPLY DEPLOYMENT ====="

                    kubectl apply \
                        -f k8s_deployment_service.yaml

                    echo "===== DEPLOYMENTS ====="

                    kubectl get deployments

                    echo "===== PODS ====="

                    kubectl get pods -o wide
                '''
            }
        }
    }

    post {

        success {
            echo "Jenkins build SUCCESS"

            setGitHubStatus(
                'Jenkins build passed',
                'SUCCESS'
            )
        }

        failure {
            echo "Jenkins build FAILED"

            setGitHubStatus(
                'Jenkins build failed - see Jenkins console',
                'FAILURE'
            )
        }

        unstable {
            echo "Jenkins build UNSTABLE"

            setGitHubStatus(
                'Jenkins build is unstable',
                'FAILURE'
            )
        }
    }
}