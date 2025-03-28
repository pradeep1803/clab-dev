pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'clab-task-app'
        DOCKER_HUB_USER = 'pradeep1803'
        AWS_REGION = 'us-east-1'
        SNS_TOPIC_ARN = 'arn:aws:sns:us-east-1:982081069647:devops'
        EC2_INSTANCE = '54.236.203.239'

        // Database Details
        MYSQL_DATABASE = 'mydata'
        MYSQL_USERNAME = 'root'
        MYSQL_ROOT_PASSWORD = 'NewPassword@123'
        MYSQL_HOST = '54.236.203.239'
        MYSQL_LOCAL_PORT = '3306'
        MYSQL_DOCKER_PORT = '3306'

        // Node.js App Port
        NODEJS_LOCAL_PORT = '3000'
    }

    stages {
        stage('Initialize Variables') {
            steps {
                script {
                    env.DOCKER_TAG = "latest-${System.currentTimeMillis()}"
                    env.CONTAINER_NAME = "clab-container-${System.currentTimeMillis()}"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                script {
                    git branch: 'master', url: 'https://github.com/pradeep1803/clab-dev.git'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                }
            }
        }

        stage('Tag & Push Docker Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-credentials', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_PASSWORD')]) {
                    script {
                        sh """
                            docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:${DOCKER_TAG}
                            echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_HUB_USER" --password-stdin
                            docker push ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        """
                    }
                }
            }
        }

        stage('Deploy on EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    script {
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@${EC2_INSTANCE} '
                            docker pull ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:${DOCKER_TAG} &&
                            
                            # Stop and remove old container if exists
                            docker stop \$(docker ps -q --filter ancestor=${DOCKER_HUB_USER}/${DOCKER_IMAGE}) || true &&
                            docker rm \$(docker ps -aq --filter ancestor=${DOCKER_HUB_USER}/${DOCKER_IMAGE}) || true &&
                            
                            # Run new container with MySQL credentials
                            docker run -d --name ${CONTAINER_NAME} -p ${NODEJS_LOCAL_PORT}:${NODEJS_LOCAL_PORT} \
                                --restart always \
                                -e MYSQL_DATABASE="${MYSQL_DATABASE}" \
                                -e MYSQL_USERNAME="${MYSQL_USERNAME}" \
                                -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
                                -e MYSQL_HOST="${MYSQL_HOST}" \
                                -e MYSQL_LOCAL_PORT="${MYSQL_LOCAL_PORT}" \
                                -e MYSQL_DOCKER_PORT="${MYSQL_DOCKER_PORT}" \
                                -e NODE_ENV="production" \
                                ${DOCKER_HUB_USER}/${DOCKER_IMAGE}:${DOCKER_TAG}
                            '
                        """
                    }
                }
            }
        }

        stage('Notify Success via AWS SNS') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    script {
                        sh """
                            aws sns publish --region ${AWS_REGION} --topic-arn ${SNS_TOPIC_ARN} --message 'Build & Deployment successful!'
                        """
                    }
                }
            }
        }
    }

    post {
        failure {
            withCredentials([aws(credentialsId: 'aws-credentials')]) {
                script {
                    sh """
                        aws sns publish --region ${AWS_REGION} --topic-arn ${SNS_TOPIC_ARN} --message 'Build & Deployment failed!'
                    """
                }
            }
        }
    }
}