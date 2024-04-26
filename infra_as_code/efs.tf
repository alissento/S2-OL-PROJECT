resource "aws_efs_file_system" "wordpressEFS" {
  creation_token = "wordpressEFSToken"

  tags = {
    Name = "wordpressEFS"
  }
}

resource "aws_efs_mount_target" "efsMountA" {
  file_system_id = aws_efs_file_system.wordpressEFS.id
  subnet_id      = aws_subnet.EFS-1A.id
}

resource "aws_efs_mount_target" "efsMountB" {
  file_system_id = aws_efs_file_system.wordpressEFS.id
  subnet_id      = aws_subnet.EFS-1B.id
}