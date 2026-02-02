#!/bin/bash

# Rollback BIA - Voltar para versão anterior

set -e

CLUSTER="cluster-bia"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"

echo "🔄 Rollback BIA"

# Listar últimas 5 task definitions
echo "📋 Últimas versões disponíveis:"
aws ecs list-task-definitions \
    --family-prefix ${TASK_FAMILY} \
    --status ACTIVE \
    --sort DESC \
    --max-items 5 \
    --query 'taskDefinitionArns[]' \
    --output table

echo
read -p "🎯 Digite a revisão para rollback (ex: 42): " REVISION

if [[ -z "$REVISION" ]]; then
    echo "❌ Revisão não informada"
    exit 1
fi

TARGET_TASK_DEF="${TASK_FAMILY}:${REVISION}"

# Verificar se existe
aws ecs describe-task-definition --task-definition ${TARGET_TASK_DEF} > /dev/null

echo "🔄 Fazendo rollback para: ${TARGET_TASK_DEF}"

aws ecs update-service \
    --cluster ${CLUSTER} \
    --service ${SERVICE} \
    --task-definition ${TARGET_TASK_DEF} \
    --query 'service.{serviceName:serviceName,taskDefinition:taskDefinition}' \
    --output table

echo "✅ Rollback concluído!"
