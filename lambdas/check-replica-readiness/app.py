import os
from datetime import datetime, timedelta, timezone

import boto3
from botocore.exceptions import ClientError


def lambda_handler(event, context):
    """
    Check whether the DR read replica is ready for promotion.
    """
    dr_region = os.environ["DR_REGION"]
    replica_id = os.environ["DR_REPLICA_IDENTIFIER"]
    max_lag = int(os.environ.get("MAX_REPLICATION_LAG_SECONDS", "30"))

    rds = boto3.client("rds", region_name=dr_region)
    cloudwatch = boto3.client("cloudwatch", region_name=dr_region)

    try:
        dbs = rds.describe_db_instances(DBInstanceIdentifier=replica_id)["DBInstances"]
        if not dbs:
            return {
                "replica_ready": False,
                "replica_identifier": replica_id,
                "replica_status": "NOT_FOUND",
                "replication_lag_seconds": -1
            }

        db = dbs[0]
        status = db["DBInstanceStatus"]

        now = datetime.now(timezone.utc)
        metric = cloudwatch.get_metric_statistics(
            Namespace="AWS/RDS",
            MetricName="ReplicaLag",
            Dimensions=[
                {"Name": "DBInstanceIdentifier", "Value": replica_id}
            ],
            StartTime=now - timedelta(minutes=10),
            EndTime=now,
            Period=60,
            Statistics=["Maximum"]
        )

        datapoints = metric.get("Datapoints", [])
        replication_lag = 0
        if datapoints:
            latest = sorted(datapoints, key=lambda x: x["Timestamp"])[-1]
            replication_lag = int(latest["Maximum"])

        replica_ready = status == "available" and replication_lag <= max_lag

        return {
            "replica_ready": replica_ready,
            "replica_identifier": replica_id,
            "replica_status": status,
            "replication_lag_seconds": replication_lag
        }

    except ClientError as exc:
        return {
            "replica_ready": False,
            "replica_identifier": replica_id,
            "replica_status": "ERROR",
            "replication_lag_seconds": -1,
            "error": str(exc)
        }