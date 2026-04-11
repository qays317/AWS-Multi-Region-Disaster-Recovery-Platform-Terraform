import os
import boto3
from botocore.exceptions import ClientError


def lambda_handler(event, context):
    """
    Scale up the ECS service in the DR region.

    Expected environment variables:
      - DR_REGION
      - ECS_CLUSTER_NAME
      - ECS_SERVICE_NAME
      - DR_DESIRED_COUNT

    Output:
      {
        "scale_up_started": true/false,
        "cluster": "...",
        "service": "...",
        "desired_count": 2,
        "running_count": 0,
        "pending_count": 1
      }
    """
    dr_region = os.environ["DR_REGION"]
    cluster_name = os.environ["ECS_CLUSTER_NAME"]
    service_name = os.environ["ECS_SERVICE_NAME"]
    desired_count = int(os.environ.get("DR_DESIRED_COUNT", "2"))

    ecs = boto3.client("ecs", region_name=dr_region)

    try:
        response = ecs.update_service(
            cluster=cluster_name,
            service=service_name,
            desiredCount=desired_count
        )

        service = response["service"]

        return {
            "scale_up_started": True,
            "cluster": cluster_name,
            "service": service_name,
            "desired_count": service["desiredCount"],
            "running_count": service["runningCount"],
            "pending_count": service["pendingCount"]
        }

    except ClientError as exc:
        return {
            "scale_up_started": False,
            "cluster": cluster_name,
            "service": service_name,
            "desired_count": desired_count,
            "error": str(exc)
        }