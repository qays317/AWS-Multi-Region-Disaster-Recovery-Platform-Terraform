import json
import os
import socket

import boto3
import pymysql


def get_secret(secret_arn: str) -> dict:
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_arn)
    return json.loads(response["SecretString"])


def lambda_handler(event, context):
    """
    Validate that the promoted DR database is writable.

    Expected environment variables:
      - DB_SECRET_ARN
      - DB_CONNECT_TIMEOUT

    Secret JSON example:
      {
        "username": "...",
        "password": "...",
        "dbname": "...",
        "host": "...",
        "port": 3306
      }
    """
    db_secret_arn = os.environ["DB_SECRET_ARN"]
    timeout = int(os.environ.get("DB_CONNECT_TIMEOUT", "5"))

    conn = None

    try:
        secret = get_secret(db_secret_arn)

        db_host = secret["host"]
        db_port = int(secret.get("port", 3306))
        db_name = secret["dbname"]
        db_user = secret["username"]
        db_password = secret["password"]

        socket.create_connection((db_host, db_port), timeout=timeout).close()

        conn = pymysql.connect(
            host=db_host,
            port=db_port,
            user=db_user,
            password=db_password,
            database=db_name,
            connect_timeout=timeout,
            autocommit=True,
            cursorclass=pymysql.cursors.Cursor,
        )

        with conn.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()

            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS dr_failover_write_test (
                    id INT PRIMARY KEY AUTO_INCREMENT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            cursor.execute("INSERT INTO dr_failover_write_test () VALUES ()")

        return {
            "db_writable": True,
            "db_host": db_host,
            "db_name": db_name,
            "message": "Database is reachable and writable"
        }

    except Exception as exc:
        return {
            "db_writable": False,
            "message": f"Database write validation failed: {str(exc)}"
        }

    finally:
        if conn:
            conn.close()