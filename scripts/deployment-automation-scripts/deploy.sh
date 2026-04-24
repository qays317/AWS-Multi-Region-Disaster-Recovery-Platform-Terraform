#!/bin/bash

set -e
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/stacks_config.sh" 

# Validate TF backend bucket
if [ -z "$TF_STATE_BUCKET_NAME" ]; then
  echo "❌ ERROR: TF_STATE_BUCKET_NAME is required"; exit 1
fi

echo "Deploying WordPress Infrastructure..."
echo "Backend region: $TF_STATE_BUCKET_REGION"
echo "Deployment region: ${AWS_REGION:-<not-set>}"

echo "Checking backend S3 bucket..."
if ! aws s3 ls "s3://$TF_STATE_BUCKET_NAME" --region "$TF_STATE_BUCKET_REGION" >/dev/null 2>&1; then
  echo "Creating backend bucket..."
  aws s3 mb "s3://$TF_STATE_BUCKET_NAME" --region "$TF_STATE_BUCKET_REGION"
  aws s3api put-bucket-versioning --bucket "$TF_STATE_BUCKET_NAME" --versioning-configuration Status=Enabled --region "$TF_STATE_BUCKET_REGION"
fi

# -----------------------------
# Function to deploy a stack
# -----------------------------
deploy_stack() {
  local stack="$1"
  echo "🟦 Deploying: $stack"

  terraform -chdir="environments/$stack" init -reconfigure -upgrade \
    -backend-config="bucket=$TF_STATE_BUCKET_NAME" \
    -backend-config="key=environments/$stack/terraform.tfstate" \
    -backend-config="region=$TF_STATE_BUCKET_REGION"

  terraform -chdir="environments/$stack" apply \
    ${STACK_VARS[$stack]} \
    -auto-approve

  echo "✅ Done: $stack"
}

# -----------------------------
# DEPLOY ORDER
# -----------------------------

deploy_stack "global/iam"
deploy_stack "global/oac"
deploy_stack "primary/network"
deploy_stack "primary/rds"
deploy_stack "primary/rds"

echo "Running DB bootstrap Lambda..."

aws lambda invoke \
  --function-name primary-db-setup \
  --payload '{"trigger":"terraform"}' \
  --cli-binary-format raw-in-base64-out \
  --log-type Tail \
  /tmp/db-bootstrap.json \
  --region us-east-1 > /tmp/db-bootstrap-meta.json

echo "=== Lambda payload ==="
cat /tmp/db-bootstrap.json
echo

echo "=== Lambda metadata ==="
cat /tmp/db-bootstrap-meta.json
echo



deploy_stack "dr/network"
deploy_stack "primary/s3"
deploy_stack "primary/alb"
deploy_stack "dr/read_replica_rds"
deploy_stack "dr/s3"
deploy_stack "dr/alb"
deploy_stack "global/cdn_dns"

echo "Pushing Docker images to ECR..."
./scripts/deployment-automation-scripts/pull-docker-hub-to-ecr.sh $PRIMARY_REGION "primary"
./scripts/deployment-automation-scripts/pull-docker-hub-to-ecr.sh $DR_REGION "dr"

# Read ECS cluster, service names
STACK_VARS["primary/ecs"]+=" -var ecs_cluster_name=$ECS_CLUSTER_NAME"
STACK_VARS["primary/ecs"]+=" -var ecs_service_name=$ECS_SERVICE_NAME"
STACK_VARS["dr/ecs"]+=" -var ecs_cluster_name=$ECS_CLUSTER_NAME"
STACK_VARS["dr/ecs"]+=" -var ecs_service_name=$ECS_SERVICE_NAME"


deploy_stack "primary/ecs"
deploy_stack "dr/ecs"

ECS_TASK_ROLE_ARN=$(terraform -chdir="environments/global/iam" output -raw ecs_task_role_arn)
CLOUDFRONT_DISTRIBUTION_ARN=$(terraform -chdir="environments/global/cdn_dns" output -raw cloudfront_distribution_arn)

STACK_VARS["primary/s3"]+=" \
  -var cloudfront_distribution_arn=$CLOUDFRONT_DISTRIBUTION_ARN \
  -var ecs_task_role_arn=$ECS_TASK_ROLE_ARN"
STACK_VARS["dr/s3"]+=" \
  -var cloudfront_distribution_arn=$CLOUDFRONT_DISTRIBUTION_ARN \
  -var ecs_task_role_arn=$ECS_TASK_ROLE_ARN" 

deploy_stack "primary/s3"
deploy_stack "dr/s3"

# DR Check Orchestration 
STACK_VARS["operations/dr_orchestration"]+=" \
  -var ecs_cluster_name=$ECS_CLUSTER_NAME \
  -var ecs_service_name=$ECS_SERVICE_NAME" 

deploy_stack "operations/dr_orchestration"



# Failoverr Alarms
STACK_VARS["primary/failover_alarms"]+=" \
  -var sns_email=$SNS_EMAIL \
  -var ecs_cluster_name=$ECS_CLUSTER_NAME
  -var ecs_service_name=$ECS_SERVICE_NAME"
  
deploy_stack "primary/failover_alarms"



echo "🎉 Deployment complete!"
