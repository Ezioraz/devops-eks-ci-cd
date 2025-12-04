pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        APP_NAME   = "devops-demo-app"
        ECR_REPO   = "devops-demo-repo"  // from your Terraform/ECR
    }

    options {
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Unit Check') {
            steps {
                sh '''
                cd app
                python -m venv venv
                . venv/bin/activate
                pip install --upgrade pip
                pip install -r requirements.txt
                python -m py_compile src/app.py
                '''
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    def commit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG = commit
                }
                sh '''
                cd app
                docker build -t ${APP_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    def accountId = sh(
                        script: "aws sts get-caller-identity --query Account --output text",
                        returnStdout: true
                    ).trim()

                    env.ECR_URI = "${accountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

                    sh """
                    # Create repo if it does not exist
                    aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} >/dev/null 2>&1 || \
                      aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION}

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
                    sh """
                    # Configure kubectl to talk to your EKS cluster
                    aws eks update-kubeconfig --name devops-demo-eks --region ${AWS_REGION}

                    # Replace IMAGE_PLACEHOLDER with real image and apply deployment
                    sed "s|IMAGE_PLACEHOLDER|${ECR_URI}:${IMAGE_TAG}|g" app/k8s/deployment.yaml | kubectl apply -f -

                    # Apply service as-is
                    kubectl apply -f app/k8s/service.yaml

                    # Wait for rollout to finish
                    kubectl rollout status deployment/devops-demo-deployment --timeout=180s
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "Deployment failed. Dumping pod status..."
            sh '''
            kubectl get pods -o wide || true
            kubectl describe deployment devops-demo-deployment || true
            '''
        }
    }
}
