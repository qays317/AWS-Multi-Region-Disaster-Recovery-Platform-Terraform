import os
import boto3
from botocore.exceptions import ClientError

cloudwatch = boto3.client("cloudwatch")


def lambda_handler(event, context):
    alarm_name = os.environ["PRIMARY_ALARM_NAME"]

    try:
        response = cloudwatch.describe_alarms(
            AlarmNames=[alarm_name],
            AlarmTypes=["CompositeAlarm", "MetricAlarm"]
        )

        composite_alarms = response.get("CompositeAlarms", [])
        metric_alarms = response.get("MetricAlarms", [])
        alarms = composite_alarms if composite_alarms else metric_alarms

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
