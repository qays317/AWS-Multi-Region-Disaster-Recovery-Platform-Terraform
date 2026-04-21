ecs_task_definition_config = {
    name = "wordpress-task-definition"
    family = "wordpress-task"
    cpu = "1024"
    memory = "2048"
    rds_name = "mysql"
}

ecs_service_sg_name = "wordpress-service-SG"


