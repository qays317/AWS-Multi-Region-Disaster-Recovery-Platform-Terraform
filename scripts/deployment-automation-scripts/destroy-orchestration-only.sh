#!/bin/bash

set -e

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/stacks_config.sh"

if [ -z "$TF_STATE_BUCKET_NAME" ]; then
  echo "❌ ERROR: TF_STATE_BUCKET_NAME variable is required"
  exit 1
fi

echo "🔥 Starting partial destruction for failover alarms and DR orchestration only..."
echo ""

init_stack() {
  local stack="$1"

  terraform -chdir="environments/$stack" init -reconfigure \
    -backend-config="bucket=$TF_STATE_BUCKET_NAME" \
    -backend-config="key=environments/$stack/terraform.tfstate" \
    -backend-config="region=$TF_STATE_BUCKET_REGION"
}

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
# Shared values needed by stacks
# -----------------------------
ECS_CLUSTER_NAME="${ECS_CLUSTER_NAME:-wordpress-cluster}"
ECS_SERVICE_NAME="${ECS_SERVICE_NAME:-wordpress-service}"

STACK_VARS["primary/failover_alarms"]+=" \
  -var ecs_cluster_name=$ECS_CLUSTER_NAME \
  -var ecs_service_name=$ECS_SERVICE_NAME"

STACK_VARS["operations/dr_orchestration"]+=" \
  -var ecs_cluster_name=$ECS_CLUSTER_NAME \
  -var ecs_service_name=$ECS_SERVICE_NAME"

# -----------------------------
# Destroy only the stacks that must be recreated in the new region
# -----------------------------
destroy_stack "operations/dr_orchestration"
destroy_stack "primary/failover_alarms"

echo ""
echo "🎉 Partial destroy completed successfully."
echo "Only failover alarms and DR orchestration stacks were destroyed."
