#!/bin/bash

set -e

# Load shared configuration
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/stacks_config.sh"

if [ -z "$TF_STATE_BUCKET_NAME" ]; then
  echo "❌ ERROR: TF_STATE_BUCKET_NAME variable is required"
  echo "Set TF_STATE_BUCKET_NAME in config.sh"
  exit 1
fi

echo "🔥 Starting AWS ECS WordPress Infrastructure Destruction..."
echo "⚠️  WARNING: This will destroy ALL resources created by deploy.sh"
echo "⚠️  This action is IRREVERSIBLE!"
echo ""

# Skip confirmation when running in CI
if [[ "$CI" == "true" ]]; then
  confirm="yes"
else
  read -p "Are you sure? (yes/no): " confirm
fi

if [[ "$confirm" != "yes" ]]; then
  echo "❌ Destruction cancelled."
  exit 1
fi

echo ""
echo "🔥 Destroying resources in reverse order..."
echo ""

# -----------------------------
# Function to init a stack
# -----------------------------
init_stack() {
  local stack="$1"

  terraform -chdir="environments/$stack" init -reconfigure \
    -backend-config="bucket=$TF_STATE_BUCKET_NAME" \
    -backend-config="key=environments/$stack/terraform.tfstate" \
    -backend-config="region=$TF_STATE_BUCKET_REGION"
}

# -----------------------------
# Function to destroy a stack
# -----------------------------
destroy_stack() {
  local stack="$1"
  echo "🟦 Destroying: $stack"

  init_stack "$stack"

  terraform -chdir="environments/$stack" destroy \
    ${STACK_VARS[$stack]} \
    -auto-approve

  echo "✅ Done: $stack"
}

# -----------------------------
# DESTROY ORDER
# -----------------------------

echo "🧹 Removing DB bootstrap Lambda to shorten teardown time..."
init_stack "primary/rds"
terraform -chdir="environments/primary/rds" destroy \
  ${STACK_VARS["primary/rds"]} \
  -target=aws_lambda_function.lambda \
  -target=aws_cloudwatch_log_group.lambda_logs \
  -target=null_resource.invoke_lambda_after_creation \
  -target=null_resource.tag_rds_master_secret \
  -auto-approve || true


# Failoverr Alarms
STACK_VARS["primary/failover_alarms"]+=" \
  -var ecs_cluster_name=$ECS_CLUSTER_NAME
  -var ecs_service_name=$ECS_SERVICE_NAME"

destroy_stack "primary/failover_alarms"



STACK_VARS["operations/dr_orchestration"]+=" \
  -var ecs_cluster_name=$ECS_CLUSTER_NAME \
  -var ecs_service_name=$ECS_SERVICE_NAME"

destroy_stack "operations/dr_orchestration"


# Read ECS cluster, service names
STACK_VARS["primary/ecs"]+=" -var ecs_cluster_name=$ECS_CLUSTER_NAME"
STACK_VARS["primary/ecs"]+=" -var ecs_service_name=$ECS_SERVICE_NAME"
STACK_VARS["dr/ecs"]+=" -var ecs_cluster_name=$ECS_CLUSTER_NAME"
STACK_VARS["dr/ecs"]+=" -var ecs_service_name=$ECS_SERVICE_NAME"

destroy_stack "dr/ecs"
destroy_stack "primary/ecs"

# Destroy primary ECR repository
echo "🗑️  Cleaning up primary ECR repository..."
if aws ecr describe-repositories \
  --repository-names "$ECR_REPO_NAME" \
  --region "$PRIMARY_REGION" >/dev/null 2>&1; then

  echo "Deleting primary ECR repository: $ECR_REPO_NAME"

  aws ecr delete-repository \
    --repository-name "$ECR_REPO_NAME" \
    --region "$PRIMARY_REGION" \
    --force || true
else
  echo "Primary ECR repository does not exist — skipping."
fi

# Destroy DR ECR repository
echo "🗑️  Cleaning up DR ECR repository..."
if aws ecr describe-repositories \
  --repository-names "$ECR_REPO_NAME" \
  --region "$DR_REGION" >/dev/null 2>&1; then

  echo "Deleting DR ECR repository: $ECR_REPO_NAME"

  aws ecr delete-repository \
    --repository-name "$ECR_REPO_NAME" \
    --region "$DR_REGION" \
    --force || true
else
  echo "DR ECR repository does not exist — skipping."
fi

if [[ -n "${RUNTIME_DIR:-}" && -d "${RUNTIME_DIR}" ]]; then
  echo "Removing runtime directory..."
  rm -rf "${RUNTIME_DIR}" || true
else
  echo "Runtime directory does not exist — nothing to remove."
fi

destroy_stack "global/cdn_dns"
destroy_stack "dr/alb"
init_stack "primary/s3"
destroy_stack "dr/s3"
destroy_stack "dr/read_replica_rds"
destroy_stack "primary/alb"
destroy_stack "primary/s3"
destroy_stack "dr/network"
destroy_stack "primary/rds"
destroy_stack "primary/network"
destroy_stack "global/oac"
destroy_stack "global/iam"

echo ""
echo "🎉 All resources have been successfully destroyed!"
echo ""
echo "Note: Some resources like S3 buckets with versioning enabled"
echo "may require manual cleanup if they contain data."
