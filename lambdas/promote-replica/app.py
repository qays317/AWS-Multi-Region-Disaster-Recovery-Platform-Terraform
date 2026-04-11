import os
import boto3
from botocore.exceptions import ClientError


def lambda_handler(event, context):
    """
    Promote the DR read replica.

    Expected environment variables:
      - DR_REGION
      - DR_REPLICA_IDENTIFIER
    """
    dr_region = os.environ["DR_REGION"]
    replica_id = os.environ["DR_REPLICA_IDENTIFIER"]

    rds = boto3.client("rds", region_name=dr_region)

    try:
        response = rds.promote_read_replica(
            DBInstanceIdentifier=replica_id
        )

        db = response["DBInstance"]

        return {
            "promotion_started": True,
            "replica_identifier": replica_id,
            "db_status": db["DBInstanceStatus"]
        }

    except ClientError as exc:
        error_code = exc.response["Error"]["Code"]

        # لو كانت already promoted أو ليست replica anymore
        return {
            "promotion_started": False,
            "replica_identifier": replica_id,
            "db_status": "ERROR",
            "error_code": error_code,
            "error": str(exc)
        }