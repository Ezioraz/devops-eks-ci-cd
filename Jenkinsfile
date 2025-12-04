pipeline {
    agent any

    environment {
        AWS_REGION     = "ap-south-1"
        ECR_REPO_NAME  = "devops-demo-repo"  // must match Terraform
        APP_NAME       = "devops-demo"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                sh '''
                cd app
                pip install -r requirements.txt
                python -m py_compile src/app.py
                '''
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    def commit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG = "${commit}"
                }
                sh '''
                cd app
                docker build -t ${APP_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Login to ECR & Push') {
            steps {
                script {
                    def account_id = sh(
                        script: "aws sts get-caller-identity --query Account --output text",
                        returnStdout: true
                    ).trim()

                    env.ECR_URI = "${account_id}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}
                    docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}
                    docker push ${ECR_URI}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh '''
                    aws eks update-kubeconfig --name devops-demo-eks --region ${AWS_REGION}

                    sed -e "s|<ECR_REPO_URL>|${ECR_URI}:${IMAGE_TAG}|g" app/k8s/deployment.yaml | kubectl apply -f -
                    kubectl apply -f app/k8s/service.yaml
                    '''
                }
            }
        }
    }
}
