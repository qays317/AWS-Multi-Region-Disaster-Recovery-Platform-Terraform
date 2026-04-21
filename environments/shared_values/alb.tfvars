target_group_config = {
    name = "wordpress-tg"
    health_check_enabled = true
    health_check_interval = 30
    health_check_timeout = 10
    healthy_threshold = 2
    unhealthy_threshold = 5
    matcher = "200,302"
} 

alb_name = "wordpress-alb"
