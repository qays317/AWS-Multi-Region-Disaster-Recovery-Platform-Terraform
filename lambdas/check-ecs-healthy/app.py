import os
import boto3
from botocore.exceptions import ClientError


def lambda_handler(event, context):
    """
    Check whether the ECS service in the DR region is healthy and stable.

    Expected environment variables:
      - DR_REGION
      - ECS_CLUSTER_NAME
      - ECS_SERVICE_NAME

    Output:
      {
        "ecs_healthy": true/false,
        "cluster": "...",
        "service": "...",
        "desired_count": 2,
        "running_count": 2,
        "pending_count": 0,
        "service_status": "ACTIVE"
      }
    """
    dr_region = os.environ["DR_REGION"]
    cluster_name = os.environ["ECS_CLUSTER_NAME"]
    service_name = os.environ["ECS_SERVICE_NAME"]

    ecs = boto3.client("ecs", region_name=dr_region)

    try:
        response = ecs.describe_services(
            cluster=cluster_name,
            services=[service_name]
        )

        services = response.get("services", [])
        if not services:
            return {
                "ecs_healthy": False,
                "cluster": cluster_name,
                "service": service_name,
                "message": "Service not found"
            }

        service = services[0]

        desired = service.get("desiredCount", 0)
        running = service.get("runningCount", 0)
        pending = service.get("pendingCount", 0)
        status = service.get("status", "UNKNOWN")

        deployments = service.get("deployments", [])
        primary_deployment = next(
            (d for d in deployments if d.get("status") == "PRIMARY"),
            None
        )

        stable = (
            status == "ACTIVE"
            and desired > 0
            and running == desired
            and pending == 0
            and primary_deployment is not None
            and primary_deployment.get("runningCount", 0) == desired
        )

        return {
            "ecs_healthy": stable,
            "cluster": cluster_name,
            "service": service_name,
            "desired_count": desired,
            "running_count": running,
            "pending_count": pending,
            "service_status": status
        }

    except ClientError as exc:
        return {
            "ecs_healthy": False,
            "cluster": cluster_name,
            "service": service_name,
            "message": str(exc)
        }