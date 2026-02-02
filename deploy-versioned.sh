#!/bin/bash

# Deploy Versionado BIA - Commit Hash Versioning
# Não sobrepõe os scripts existentes (deploy.sh, build.sh, deploy-ecs.sh)

set -e

# Configurações
ECR_REGISTRY="434729668520.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPO="bia"
CLUSTER="cluster-bia"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"
REGION="us-east-1"

# Obter commit hash
COMMIT_HASH=$(git rev-parse --short HEAD)
IMAGE_TAG="v-${COMMIT_HASH}"
FULL_IMAGE_URI="${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"

echo "🚀 Deploy Versionado BIA"
echo "📦 Commit: ${COMMIT_HASH}"
echo "🏷️  Tag: ${IMAGE_TAG}"
echo "📍 Image: ${FULL_IMAGE_URI}"
echo

# 1. Build e Push da imagem
echo "1️⃣  Building e pushing imagem..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker build -t ${ECR_REPO}:${IMAGE_TAG} .
docker tag ${ECR_REPO}:${IMAGE_TAG} ${FULL_IMAGE_URI}
docker push ${FULL_IMAGE_URI}

# 2. Criar nova task definition
echo "2️⃣  Criando task definition..."
TASK_DEF_JSON=$(aws ecs describe-task-definition --task-definition ${TASK_FAMILY} --query 'taskDefinition' --output json)

# Atualizar imagem na task definition
NEW_TASK_DEF=$(echo $TASK_DEF_JSON | jq --arg image "$FULL_IMAGE_URI" '
  .containerDefinitions[0].image = $image |
  del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)
')

# Registrar nova task definition
NEW_REVISION=$(aws ecs register-task-definition --cli-input-json "$NEW_TASK_DEF" --query 'taskDefinition.revision' --output text)

echo "✅ Task Definition criada: ${TASK_FAMILY}:${NEW_REVISION}"

# 3. Preview do deploy
echo
echo "📋 PREVIEW DO DEPLOY:"
echo "   Cluster: ${CLUSTER}"
echo "   Service: ${SERVICE}"
echo "   Task Definition: ${TASK_FAMILY}:${NEW_REVISION}"
echo "   Image: ${FULL_IMAGE_URI}"
echo

# 4. Confirmação
read -p "🤔 Continuar com o deploy? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deploy cancelado"
    exit 0
fi

# 5. Deploy
echo "3️⃣  Executando deploy..."
aws ecs update-service \
    --cluster ${CLUSTER} \
    --service ${SERVICE} \
    --task-definition ${TASK_FAMILY}:${NEW_REVISION} \
    --query 'service.{serviceName:serviceName,taskDefinition:taskDefinition,desiredCount:desiredCount}' \
    --output table

echo
echo "🎉 Deploy concluído!"
echo "📊 Para acompanhar: aws ecs describe-services --cluster ${CLUSTER} --services ${SERVICE}"
