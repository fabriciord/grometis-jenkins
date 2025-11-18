pipeline {
    agent any
    
    environment {
        // Configurações do Docker Hub
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKERHUB_USERNAME = 'fabriciobackend'
        DOCKER_IMAGE_NAME = "${DOCKERHUB_USERNAME}/grometis-app"
        
        // Configurações do projeto
        APP_NAME = 'grometis-app'
        
        // Configurações de deploy
        DEPLOY_HOST = '192.168.15.6'
        DEPLOY_USER = 'grometis'
        SSH_CREDENTIALS_ID = 'mahindra'
        
        // Tag da imagem (usando número do build ou branch)
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
        LATEST_IMAGE = "${DOCKER_IMAGE_NAME}:latest"
    }
    
    options {
        // Manter apenas os últimos 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        
        // Timeout para o pipeline completo
        timeout(time: 30, unit: 'MINUTES')
        
        // Desabilitar checkout automático
        skipDefaultCheckout(false)
        
        // Adicionar timestamps nos logs
        timestamps()
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage: Checkout do Repositório'
                    echo '========================================='
                }
                
                // Limpar workspace antes do checkout
                cleanWs()
                
                // Fazer checkout do repositório
                checkout scm
                
                script {
                    // Exibir informações do commit
                    sh '''
                        echo "Branch: ${GIT_BRANCH}"
                        echo "Commit: ${GIT_COMMIT}"
                        git log -1 --pretty=format:"Author: %an%nDate: %ad%nMessage: %s" --date=short
                    '''
                }
            }
        }
        
        stage('Environment Check') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage: Verificação do Ambiente'
                    echo '========================================='
                }
                
                // Verificar versões das ferramentas
                sh '''
                    echo "Docker Version:"
                    docker --version
                    
                    echo "\nDocker Compose Version:"
                    docker-compose --version
                    
                    echo "\nGit Version:"
                    git --version
                    
                    echo "\nJava Version:"
                    java -version
                    
                    echo "\nNode Version (se disponível):"
                    node --version || echo "Node não instalado"
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage: Build da Imagem Docker'
                    echo '========================================='
                    echo "Building: ${FULL_IMAGE_NAME}"
                }
                
                // Build da imagem Docker
                sh """
                    docker build \
                        -t ${FULL_IMAGE_NAME} \
                        -t ${LATEST_IMAGE} \
                        --build-arg BUILD_NUMBER=${BUILD_NUMBER} \
                        --build-arg GIT_COMMIT=${GIT_COMMIT} \
                        --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                        .
                """
                
                // Verificar se a imagem foi criada
                sh """
                    docker images | grep ${DOCKER_IMAGE_NAME}
                """
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage: Teste da Imagem Docker'
                    echo '========================================='
                }
                
                // Testar se a imagem funciona (health check básico)
                sh """
                    echo "Testing image: ${FULL_IMAGE_NAME}"
                    docker run --rm ${FULL_IMAGE_NAME} echo "Image test successful"
                """
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage: Push para Docker Hub'
                    echo '========================================='
                }
                
                // Login no Docker Hub e push da imagem
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDENTIALS_ID}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "Logging into Docker Hub..."
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        
                        echo "Pushing image with tag: ${IMAGE_TAG}"
                        docker push ${FULL_IMAGE_NAME}
                        
                        echo "Pushing image with tag: latest"
                        docker push ${LATEST_IMAGE}
                        
                        echo "Logging out from Docker Hub..."
                        docker logout
                    '''
                }
                
                script {
                    echo "✓ Image pushed successfully:"
                    echo "  - ${FULL_IMAGE_NAME}"
                    echo "  - ${LATEST_IMAGE}"
                }
            }
        }
        
        stage('Deploy to VM') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage: Deploy na VM'
                    echo '========================================='
                    echo "Deploying to: ${DEPLOY_USER}@${DEPLOY_HOST}"
                }
                
                // Deploy via SSH usando withCredentials
                withCredentials([sshUserPrivateKey(credentialsId: "${SSH_CREDENTIALS_ID}", keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh """
                        # Configurar SSH para usar a chave privada
                        mkdir -p ~/.ssh
                        chmod 700 ~/.ssh
                        cp "\${SSH_KEY}" ~/.ssh/deploy_key
                        chmod 600 ~/.ssh/deploy_key
                        
                        # Criar diretório para o projeto se não existir
                        ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                            mkdir -p ~/deployments/${APP_NAME}
                        '
                        
                        # Copiar docker-compose.yml para o servidor
                        scp -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no docker-compose.yml ${DEPLOY_USER}@${DEPLOY_HOST}:~/deployments/${APP_NAME}/
                        
                        # Copiar arquivo .env se existir
                        if [ -f .env.production ]; then
                            scp -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no .env.production ${DEPLOY_USER}@${DEPLOY_HOST}:~/deployments/${APP_NAME}/.env
                        fi
                        
                        # Executar deploy no servidor
                        ssh -i ~/.ssh/deploy_key -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                            cd ~/deployments/${APP_NAME}
                            
                            # Definir variável de ambiente para a imagem
                            export DOCKER_IMAGE=${FULL_IMAGE_NAME}
                            export IMAGE_TAG=${IMAGE_TAG}
                            
                            echo "Pulling latest image..."
                            docker-compose pull
                            
                            echo "Stopping old containers..."
                            docker-compose down || true
                            
                            echo "Starting new containers..."
                            docker-compose up -d
                            
                            echo "Waiting for containers to be healthy..."
                            sleep 5
                            
                            echo "Checking container status..."
                            docker-compose ps
                            
                            echo "Cleaning up old images..."
                            docker image prune -f
                        '
                        
                        # Limpar chave temporária
                        rm -f ~/.ssh/deploy_key
                    """
                }
                
                script {
                    echo "✓ Deploy completed successfully!"
                    echo "Application is running on: http://${DEPLOY_HOST}"
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo '========================================='
                    echo 'Stage: Verificação do Deploy'
                    echo '========================================='
                }
                
                // Verificar se a aplicação está respondendo
                sshagent(credentials: ["${SSH_CREDENTIALS_ID}"]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                            cd ~/deployments/${APP_NAME}
                            
                            echo "Container status:"
                            docker-compose ps
                            
                            echo "\nContainer logs (last 20 lines):"
                            docker-compose logs --tail=20
                            
                            echo "\nChecking application health..."
                            # Aguardar alguns segundos para a aplicação iniciar
                            sleep 5
                            
                            # Verificar se o container está rodando
                            if docker-compose ps | grep -q "Up"; then
                                echo "✓ Application is running!"
                            else
                                echo "✗ Application is not running!"
                                exit 1
                            fi
                        '
                    """
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo '========================================='
                echo '✓ Pipeline executado com SUCESSO!'
                echo '========================================='
                echo "Build Number: ${BUILD_NUMBER}"
                echo "Docker Image: ${FULL_IMAGE_NAME}"
                echo "Deployed to: http://${DEPLOY_HOST}"
                echo '========================================='
            }
            
            // Limpar imagens antigas localmente
            sh '''
                echo "Cleaning up local Docker images..."
                docker image prune -f || true
            '''
        }
        
        failure {
            script {
                echo '========================================='
                echo '✗ Pipeline FALHOU!'
                echo '========================================='
                echo "Build Number: ${BUILD_NUMBER}"
                echo "Check the logs above for error details"
                echo '========================================='
            }
        }
        
        always {
            // Limpar workspace se necessário
            script {
                echo 'Cleaning up workspace...'
            }
            
            // Sempre fazer logout do Docker Hub
            sh 'docker logout || true'
        }
    }
}
