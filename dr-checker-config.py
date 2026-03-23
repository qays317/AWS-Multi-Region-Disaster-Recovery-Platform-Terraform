############################################
# Regions
############################################
regions:
  primary: us-east-1
  dr: ca-central-1

############################################
# DR Policy
############################################
dr:
  rpo_minutes: 15

############################################
# RDS Configuration
############################################
rds:
  enabled: true
  engine: mysql
  snapshot:
    type: automated
    tag:
      key: app
      value: wordpress

############################################
# ECS Configuration
############################################
ecs:
  enabled: true
  task_definition_family: wordpress-task
  images:
    primary_uri: ""   # سيتم تمريرها من GitHub Actions
    dr_uri: ""        # سيتم تمريرها من GitHub Actions

############################################
# S3 Media Buckets
############################################
s3:
  media:
    primary_bucket: wordpress-media-primary-2004
    dr_bucket: wordpress-media-dr-2004

############################################
# CloudFront (اختياري)
############################################
cloudfront:
  distribution_id: ""   # اتركه فارغ إذا لم تستخدم CloudFront
