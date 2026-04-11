import os
import boto3
from botocore.exceptions import ClientError


def lambda_handler(event, context):
    """
    Check whether the promoted DB is now available.
    """
    dr_region = os.environ["DR_REGION"]
    replica_id = os.environ["DR_REPLICA_IDENTIFIER"]

    rds = boto3.client("rds", region_name=dr_region)

    try:
        dbs = rds.describe_db_instances(DBInstanceIdentifier=replica_id)["DBInstances"]
        if not dbs:
            return {
                "db_available": False,
                "db_status": "NOT_FOUND",
                "replica_identifier": replica_id
            }

        db = dbs[0]
        status = db["DBInstanceStatus"]

        endpoint = None
        if "Endpoint" in db:
            endpoint = db["Endpoint"].get("Address")

        return {
            "db_available": status == "available",
            "db_status": status,
            "replica_identifier": replica_id,
            "db_endpoint": endpoint
        }

    except ClientError as exc:
        return {
            "db_available": False,
            "db_status": "ERROR",
            "replica_identifier": replica_id,
            "error": str(exc)
        }