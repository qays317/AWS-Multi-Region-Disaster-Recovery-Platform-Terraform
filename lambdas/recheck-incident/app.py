import os
import boto3
from botocore.exceptions import ClientError


cloudwatch = boto3.client("cloudwatch")


def lambda_handler(event, context):
    """
    Re-check whether the incident is still real before starting failover.

    Expected environment variables:
      - PRIMARY_ALARM_NAME

    Output:
      {
        "incident_confirmed": true/false,
        "alarm_name": "...",
        "alarm_state": "ALARM|OK|INSUFFICIENT_DATA"
      }
    """
    alarm_name = os.environ["PRIMARY_ALARM_NAME"]

    try:
        response = cloudwatch.describe_alarms(
            AlarmNames=[alarm_name]
        )
        alarms = response.get("MetricAlarms", [])

        if not alarms:
            return {
                "incident_confirmed": False,
                "alarm_name": alarm_name,
                "alarm_state": "NOT_FOUND"
            }

        alarm = alarms[0]
        state = alarm["StateValue"]

        return {
            "incident_confirmed": state == "ALARM",
            "alarm_name": alarm_name,
            "alarm_state": state
        }

    except ClientError as exc:
        return {
            "incident_confirmed": False,
            "alarm_name": alarm_name,
            "alarm_state": "ERROR",
            "error": str(exc)
        }