import json
import logging
import os
import time
from typing import Any

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    dr_region = os.environ["DR_REGION"]
    replica_identifier = os.environ["DR_REPLICA_IDENTIFIER"]
    max_lag = int(os.environ.get("MAX_REPLICATION_LAG_SECONDS", "30"))
    poll_interval = int(os.environ.get("POLL_INTERVAL_SECONDS", "15"))
    max_wait = int(os.environ.get("MAX_WAIT_SECONDS", "900"))

    rds = boto3.client("rds", region_name=dr_region)

    logger.info(
        "Starting replica failover handler for replica=%s in region=%s",
        replica_identifier,
        dr_region,
    )

    db = describe_db_instance(rds, replica_identifier)
    status = db["DBInstanceStatus"]
    endpoint = db.get("Endpoint", {}).get("Address")

    lag = extract_replica_lag(db)
    logger.info("Initial replica status=%s lag=%s", status, lag)

    if status != "available":
        return {
            "replica_ready": False,
            "promotion_started": False,
            "db_available": False,
            "db_status": status,
            "replica_identifier": replica_identifier,
            "db_endpoint": endpoint,
            "message": f"Replica is not available. Current status: {status}",
        }

    if lag is None:
        logger.warning("Replica lag metric not available from RDS describe output")
    elif lag > max_lag:
        return {
            "replica_ready": False,
            "promotion_started": False,
            "db_available": False,
            "db_status": status,
            "replica_identifier": replica_identifier,
            "db_endpoint": endpoint,
            "replica_lag_seconds": lag,
            "message": f"Replica lag {lag}s exceeds max allowed {max_lag}s",
        }

    try:
        logger.info("Promoting read replica %s", replica_identifier)
        rds.promote_read_replica(DBInstanceIdentifier=replica_identifier)
    except rds.exceptions.InvalidDBInstanceStateFault:
        logger.info("Replica already being promoted or already promoted")
    except Exception as exc:
        logger.exception("Failed to start promotion")
        return {
            "replica_ready": True,
            "promotion_started": False,
            "db_available": False,
            "db_status": status,
            "replica_identifier": replica_identifier,
            "db_endpoint": endpoint,
            "message": f"Failed to promote replica: {exc}",
        }

    waited = 0
    stable_success_count = 0
    required_stable_success_count = 2

    last_status = status
    last_endpoint = endpoint
    last_checks = {}

    while waited < max_wait:
        db = describe_db_instance(rds, replica_identifier)
        status = db["DBInstanceStatus"]
        endpoint = db.get("Endpoint", {}).get("Address")

        checks = get_promotion_checks(db)
        last_status = status
        last_endpoint = endpoint
        last_checks = checks

        logger.info(
            "Polling promoted DB status=%s waited=%ss checks=%s",
            status,
            waited,
            json.dumps(checks),
        )

        if is_promotion_complete(db):
            stable_success_count += 1
            logger.info(
                "Promotion completion conditions met %s/%s times",
                stable_success_count,
                required_stable_success_count,
            )
        else:
            stable_success_count = 0

        if stable_success_count >= required_stable_success_count:
            return {
                "replica_ready": True,
                "promotion_started": True,
                "db_available": True,
                "db_status": status,
                "replica_identifier": replica_identifier,
                "db_endpoint": endpoint,
                "checks": checks,
                "message": "Replica promotion fully completed and stable",
            }

        time.sleep(poll_interval)
        waited += poll_interval

    return {
        "replica_ready": False,
        "promotion_started": True,
        "db_available": False,
        "db_status": last_status,
        "replica_identifier": replica_identifier,
        "db_endpoint": last_endpoint,
        "checks": last_checks,
        "message": f"Timed out waiting for promotion to fully complete after {max_wait}s",
    }


def describe_db_instance(rds_client: Any, db_identifier: str) -> dict[str, Any]:
    response = rds_client.describe_db_instances(DBInstanceIdentifier=db_identifier)
    return response["DBInstances"][0]


def extract_replica_lag(db_instance: dict[str, Any]) -> int | None:
    value = db_instance.get("PendingModifiedValues", {}).get("ReplicaMode")
    _ = value

    return None


def get_promotion_checks(db_instance: dict[str, Any]) -> dict[str, Any]:
    status = db_instance.get("DBInstanceStatus")
    replica_source = db_instance.get("ReadReplicaSourceDBInstanceIdentifier")
    pending = db_instance.get("PendingModifiedValues", {})
    endpoint = db_instance.get("Endpoint", {}).get("Address")

    return {
        "db_status": status,
        "is_available": status == "available",
        "replica_source_removed": not bool(replica_source),
        "read_replica_source": replica_source,
        "pending_modified_values_empty": not bool(pending),
        "pending_modified_values": pending,
        "endpoint_present": bool(endpoint),
    }


def is_promotion_complete(db_instance: dict[str, Any]) -> bool:
    checks = get_promotion_checks(db_instance)

    return (
        checks["is_available"]
        and checks["replica_source_removed"]
        and checks["pending_modified_values_empty"]
        and checks["endpoint_present"]
    )
