# Lunch template for the Autoscaling group with all necessary user data
resource "aws_launch_template" "wordpressServer" {
  name = "wordpressserver"
  image_id = "ami-098c93bd9d119c051"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.webappSG.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.wordpressInstanceProfile.name
  }

  user_data = base64encode(<<-EOF
                #!/bin/bash
                dnf -y update
                dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php php-devel stress amazon-efs-utils -y

                systemctl enable httpd
                systemctl start httpd

                mkdir -p /var/www/html/wp-content
                echo -e "${aws_efs_file_system.wordpressEFS.dns_name}:/ /var/www/html/wp-content efs _netdev,tls,iam 0 0" >> /etc/fstab
                mount -a -t efs defaults

                cd /var/www/html
                wget https://wordpress.org/latest.tar.gz
                tar -xzvf latest.tar.gz
                cp -r wordpress/* .
                rm -rf wordpress latest.tar.gz

                cp wp-config-sample.php wp-config.php
                sed -i "s/'database_name_here'/'${aws_db_instance.wordpressRDS.db_name}'/g" wp-config.php
                sed -i "s/'username_here'/'${aws_db_instance.wordpressRDS.username}'/g" wp-config.php
                sed -i "s/'password_here'/'${aws_db_instance.wordpressRDS.password}'/g" wp-config.php
                sed -i "s/'localhost'/'${aws_db_instance.wordpressRDS.endpoint}'/g" wp-config.php

                chown -R ec2-user:apache /var/www/
                chmod -R 0775 /var/www/html/wp-content/

                systemctl restart httpd

              EOF
            )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "WordpressServer"
    }
  }

} 

# Autoscaling group for the wordpress servers
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

  target_group_arns = [aws_lb_target_group.lbTargetGroup.arn]
}


# Scaling policies and cloud watch alarms necessary to have problem scaling of the websevers
# stress -c 2 -v -t 3000 for testing purposes
resource "aws_autoscaling_policy" "cpuScalingPolicy" {
  name = "cpuScalingPolicy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.wordpressAutoScalingGroup.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_high" {
  alarm_name = "cpu-alarm-high"
  alarm_description = "Alarm when load is higher than 75%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 3
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
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.wordpressAutoScalingGroup.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_low" {
  alarm_name = "cpu-alarm-low"
  alarm_description = "Alarm when load is lower than 75%"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = 3
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

# Load balancer to provide high availability
resource "aws_lb" "wordpressLoadBalancer" {
  name = "wordpressALB"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.albSG.id]
  subnets = [aws_subnet.WEBAPP-1A.id, aws_subnet.WEBAPP-1B.id ]
  
  tags = {
    Name = "wordpressALB"
  }
}

resource "aws_lb_listener" "lbListener" {
  load_balancer_arn = aws_lb.wordpressLoadBalancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lbTargetGroup.arn
  }
}
resource "aws_lb_target_group" "lbTargetGroup" {
  name = "lbTargetGroup"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.WordpressVPC.id 
}

# IAM role and instance profile for the webserver to provide them necessary permissions
resource "aws_iam_role" "wordpressRole" {
  name               = "wordpressRole"
  assume_role_policy = <<EOF
                        {
                          "Version": "2012-10-17",
                          "Statement": [
                            {
                              "Effect": "Allow",
                              "Principal": {
                                "Service": "ec2.amazonaws.com"
                              },
                              "Action": "sts:AssumeRole"
                            }
                          ]
                        }
                        EOF
}

resource "aws_iam_instance_profile" "wordpressInstanceProfile" {
  name = "example-ec2-instance-profile"
  role = aws_iam_role.wordpressRole.name
}

resource "aws_iam_policy_attachment" "wordpressPolicyAttachment" {
  name       = "example-ec2-policy-attachment"
  roles      = [aws_iam_role.wordpressRole.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
}
