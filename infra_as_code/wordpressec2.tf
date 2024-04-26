resource "aws_network_interface" "test" {
  subnet_id = aws_subnet.WEBAPP-1A.id
  security_groups = [aws_security_group.webappSG.id]
}

resource "aws_instance" "wordpressEC2" {
  ami = "ami-0f673487d7e5f89ca"
  instance_type = "t2.micro"
  
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.test.id
  }

  tags = {
    Name = "testEC2"
  }
}

