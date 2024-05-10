resource "aws_launch_template" "wordpressServer" {
  name = "wordpressserver"
  image_id = "ami-098c93bd9d119c051"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webappSG.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "WordpressServer"
    }
  }

  #TODO user data of wordpress installing and efs and rds attachment

} 

resource "aws_autoscaling_group" "wordpressAutoScalingGroup" {
  name = "wordpressAutoScalingGroup"
  desired_capacity = 1
  max_size = 2
  min_size = 1
  vpc_zone_identifier = [aws_subnet.WEBAPP-1A.id, aws_subnet.WEBAPP-1B.id]

  launch_template {
    id = aws_launch_template.wordpressServer.id
    version = "$Latest"
  }
}


resource "aws_autoscaling_policy" "cpuScalingPolicy" {
  name = "cpuScalingPolicy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 10
  autoscaling_group_name = aws_autoscaling_group.wordpressAutoScalingGroup.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_high" {
  alarm_name = "cpu-alarm-high"
  alarm_description = "Alarm when load is higher than 75%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 60
  statistic = "Average"
  threshold = 75
  alarm_actions = [aws_autoscaling_policy.cpuScalingPolicy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpressAutoScalingGroup.name
  }
}

resource "aws_autoscaling_policy" "cpuDescalingPolicy" {
  name = "cpuDescalingPolicy"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 10
  autoscaling_group_name = aws_autoscaling_group.wordpressAutoScalingGroup.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_low" {
  alarm_name = "cpu-alarm-low"
  alarm_description = "Alarm when load is lower than 75%"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 60
  statistic = "Average"
  threshold = 25
  alarm_actions = [aws_autoscaling_policy.cpuDescalingPolicy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpressAutoScalingGroup.name
  }
}