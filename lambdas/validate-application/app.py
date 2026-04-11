import os
import urllib.request
import urllib.error


def lambda_handler(event, context):
    """
    Validate that the DR application endpoint responds successfully.

    Expected environment variables:
      - APP_HEALTHCHECK_URL
      - APP_HEALTHCHECK_TIMEOUT
      - EXPECTED_STATUS_CODE

    Output:
      {
        "app_healthy": true/false,
        "url": "...",
        "status_code": 200,
        "message": "..."
      }
    """
    url = os.environ["APP_HEALTHCHECK_URL"]
    timeout = int(os.environ.get("APP_HEALTHCHECK_TIMEOUT", "10"))
    expected_status = int(os.environ.get("EXPECTED_STATUS_CODE", "200"))

    try:
        request = urllib.request.Request(
            url,
            method="GET",
            headers={"User-Agent": "dr-failover-validator/1.0"}
        )

        with urllib.request.urlopen(request, timeout=timeout) as response:
            status_code = response.getcode()

        return {
            "app_healthy": status_code == expected_status,
            "url": url,
            "status_code": status_code,
            "message": "Application validation completed"
        }

    except urllib.error.HTTPError as exc:
        return {
            "app_healthy": False,
            "url": url,
            "status_code": exc.code,
            "message": f"HTTP error: {str(exc)}"
        }
    except Exception as exc:
        return {
            "app_healthy": False,
            "url": url,
            "status_code": 0,
            "message": f"Application validation failed: {str(exc)}"
        }