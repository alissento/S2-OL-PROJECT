# Creation of EFS file system and 2 mount targets in different subnets
resource "aws_efs_file_system" "wordpressEFS" {
  creation_token = "wordpressEFSToken"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = false
  tags = {
    Name = "wordpressEFS"
  }
}

resource "aws_efs_mount_target" "efsMountA" {
  file_system_id = aws_efs_file_system.wordpressEFS.id
  subnet_id      = aws_subnet.EFS-1A.id
  security_groups = [aws_security_group.efsSG.id]
}

resource "aws_efs_mount_target" "efsMountB" {
  file_system_id = aws_efs_file_system.wordpressEFS.id
  subnet_id      = aws_subnet.EFS-1B.id
  security_groups = [aws_security_group.efsSG.id]
}

