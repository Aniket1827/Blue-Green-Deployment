pipeline {
    agent any
    
    tools {
        maven "maven3"
    }
    
    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['blue', 'green'], description: 'Choose which environment to deploy, Blue or Green?')
        choice(name: 'DOCKER_TAG', choices: ['blue', 'green'], description: 'Choose the docker tag for deployement on the already selected environment')
        booleanParam(name: 'SWITCH_TRAFFIC', defaultValue: false, description: 'Switch traffic between Blue and Green environrment')
    }
    
    environment {
        IMAGE_NAME = "aniketk1827/blue-green-deployment"
        TAG = "${params.DOCKER_TAG}"
        SCANNER_HOME = tool 'sonar-scanner'
    }
    
    stages {
        stage("Cleanup Workspace") {
            steps {
                deleteDir()
            }
        }
        
         stage('Git Checkout') {
            steps {
                git branch: 'main', credentialsId: 'git-cred', url: 'https://github.com/Aniket1827/Blue-Green-Deployment.git'
            }
        }
        
        stage("Compile") {
            steps {
                sh 'mvn compile'
            }
        }
        
         stage("Build") {
            steps {
                sh 'mvn package -DskipTests=true'
            }
        }
        
        stage("Unit Tests") {
            steps {
                sh 'mvn test -DskipTests=true'
            }
        }
        
        stage("Trivy File System Scan") {
            steps {
                sh "trivy fs --format table . "
            }
        }
        
        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('sonar') {
                    sh "$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectKey=BlueGreenDeployement -Dsonar.projectName=BlueGreenDeployement -Dsonar.java.binaries=target"
                }
            }
        }
        
        stage('Docker build') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker_hub_credentials') {
                        sh "docker build -t ${IMAGE_NAME}:${TAG} ."
                    }
                }
            }
        }
        
        // stage('Trivy Image Scan') {
        //     steps {
        //         sh "trivy image --format table -o image.html ${IMAGE_NAME}:${TAG}"
        //     }
        // }
        
        stage('Docker Push Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker_hub_credentials') {
                        sh "docker push ${IMAGE_NAME}:${TAG}"
                    }
                }
            }
        }
        
        stage('Deploy MySQL Deployment and Service') {
            steps {
                script {
                    withKubeConfig(caCertificate: '', clusterName: 'blue-green-deployment', contextName: '', credentialsId: 'k8-token', namespace: '', restrictKubeConfigAccess: false, serverUrl: 'https://760A19FCA77B331AB9596621D09515F0.gr7.us-east-1.eks.amazonaws.com') {
                        sh "kubectl apply -f mysql-ds.yml"  // Ensure you have the MySQL deployment YAML ready
                    }
                }
            }
        }
        
        stage('Deploy SVC-APP') {
            steps {
                script {
                    def currentDir = pwd()
                    def serviceFilePath = currentDir + "/k8s/manifests/service.yml"
                    withKubeConfig(caCertificate: '', clusterName: 'blue-green-deployment', contextName: '', credentialsId: 'k8-token', namespace: '', restrictKubeConfigAccess: false, serverUrl: 'https://760A19FCA77B331AB9596621D09515F0.gr7.us-east-1.eks.amazonaws.com') {
                        sh """ if ! kubectl get svc blue-green-deployment; then
                                kubectl apply -f ${serviceFilePath}
                              fi
                        """
                   }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    def currentDir = pwd()
                    def deploymentFile = ""
                    if (params.DEPLOY_ENV == 'blue') {
                        deploymentFile = 'deployment-blue.yml'
                    } else {
                        deploymentFile = 'deployment-green.yml'
                    }
                    def deploymentFilePath = currentDir + "/k8s/manifests/" + deploymentFile
                    withKubeConfig(caCertificate: '', clusterName: 'blue-green-deployment', contextName: '', credentialsId: 'k8-token', namespace: '', restrictKubeConfigAccess: false, serverUrl: 'https://760A19FCA77B331AB9596621D09515F0.gr7.us-east-1.eks.amazonaws.com') {
                        sh "kubectl apply -f ${deploymentFilePath}"
                    }
                }
            }
        }
        
        stage('Switch Traffic Between Blue & Green Environment') {
            when {
                expression { return params.SWITCH_TRAFFIC }
            }
            steps {
                script {
                    def newEnv = params.DEPLOY_ENV

                    withKubeConfig(caCertificate: '', clusterName: 'blue-green-deployment', contextName: '', credentialsId: 'k8-token', namespace: '', restrictKubeConfigAccess: false, serverUrl: 'https://760A19FCA77B331AB9596621D09515F0.gr7.us-east-1.eks.amazonaws.com') {
                        sh '''
                            kubectl patch service blue-green-service -p "{\\"spec\\": {\\"selector\\": {\\"app\\": \\"bankapp\\", \\"version\\": \\"''' + newEnv + '''\\"}}}"
                        '''
                    }
                    echo "Traffic has been switched to the ${newEnv} environment."
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    def verifyEnv = params.DEPLOY_ENV
                    withKubeConfig(caCertificate: '', clusterName: 'blue-green-deployment', contextName: '', credentialsId: 'k8-token', namespace: '', restrictKubeConfigAccess: false, serverUrl: 'https://760A19FCA77B331AB9596621D09515F0.gr7.us-east-1.eks.amazonaws.com') {
                        sh """
                        kubectl get pods -l version=${verifyEnv}
                        kubectl get svc blue-green-service
                        """
                    }
                }
            }
        }
    }
}