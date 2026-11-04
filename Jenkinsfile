def setGitHubStatus(String message, String state) {

    def repoUrl = sh(
        script: 'git config --get remote.origin.url',
        returnStdout: true
    ).trim()

    def commitSha = sh(
        script: 'git rev-parse HEAD',
        returnStdout: true
    ).trim()

    echo "GitHub repository: ${repoUrl}"
    echo "Git commit: ${commitSha}"

    step([
        $class: 'GitHubCommitStatusSetter',

        reposSource: [
            $class: 'ManuallyEnteredRepositorySource',
            url: repoUrl
        ],

        commitShaSource: [
            $class: 'ManuallyEnteredShaSource',
            sha: commitSha
        ],

        contextSource: [
            $class: 'ManuallyEnteredCommitContextSource',
            context: 'continuous-integration/jenkins'
        ],

        errorHandlers: [
            [$class: 'ShallowAnyErrorHandler']
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

        stage('Verify Java Runtime') {
            steps {
                sh '''
                    set -e
                    echo "===== JAVA RUNTIME ====="
                    java -version
                    java -XshowSettings:properties -version 2>&1 \
                        | grep -Eq 'java.specification.version = 25([[:space:]]|$)'
                '''
            }
        }

        stage('Build Artifacts') {
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


        stage('SonarQube - SAST') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        mvn clean verify \
                        org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                        -Dsonar.projectKey=numeric-application \
                        -Dsonar.projectName=numeric-application
                    '''
                }
                timeout(time: 2, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate(abortPipeline: true)
                        echo "Quality Gate status: ${qg.status}" 
                    }
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                withCredentials([
                    string(credentialsId: 'nvd-api-key',
                        variable: 'NVD_API_KEY')
                ]) {
                    timeout(time: 500, unit: 'MINUTES') {
                        sh '''
                            set +x

                            mvn org.owasp:dependency-check-maven:12.2.2:check \
                                -DnvdApiKey="$NVD_API_KEY" \
                                -DdataDirectory=/var/lib/jenkins/dependency-check-data \
                                -DassemblyAnalyzerEnabled=false \
                                -DnodeAnalyzerEnabled=false
                        '''
                    }
                }
            }

            post {
                always {
                    dependencyCheckPublisher(
                        pattern: 'target/dependency-check-report.xml',
                        skipNoReportFiles: true
                    )
                }
            }
        }


        stage('Docker Build and Push') {
            steps {
                script {
                    env.IMAGE = 'sitotest/numeric-app'
                    env.TAG = env.GIT_COMMIT
                }

                sh '''
                    set -e

                    echo "===== DOCKER BUILD ====="

                    docker build \
                        -t ${IMAGE}:${TAG} \
                        .

                    echo "===== TRIVY SECURITY SCAN ====="

                    bash trivy-scan-dockerimage.sh "${IMAGE}:${TAG}"
                '''

                withDockerRegistry([
                    credentialsId: 'Docker-hub',
                    url: ''
                ]) {

                    sh '''
                        set -e

                        echo "===== DOCKER PUSH ====="

                        docker push ${IMAGE}:${TAG}

                        echo "===== DOCKER TAG LATEST ====="

                        docker tag \
                            ${IMAGE}:${TAG} \
                            ${IMAGE}:latest

                        echo "===== DOCKER PUSH LATEST ====="

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
            echo "GIT_COMMIT=${env.GIT_COMMIT}"

            setGitHubStatus(
                'Jenkins build passed',
                'SUCCESS'
            )
        }

        failure {
            echo "Jenkins build FAILED"
            echo "GIT_COMMIT=${env.GIT_COMMIT}"

            setGitHubStatus(
                'Jenkins build failed - see Jenkins console',
                'FAILURE'
            )
        }

        unstable {
            echo "Jenkins build UNSTABLE"
            echo "GIT_COMMIT=${env.GIT_COMMIT}"

            setGitHubStatus(
                'Jenkins build is unstable',
                'FAILURE'
            )
        }
    }
}