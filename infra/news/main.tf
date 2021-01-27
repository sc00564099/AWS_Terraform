data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.prefix}/base/vpc_id"
}
data "aws_ssm_parameter" "subnet" {
  name = "/${var.prefix}/base/subnet/a/id"
}
data "aws_ssm_parameter" "ecr" {
  name = "/${var.prefix}/base/ecr"
}

locals {
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  subnet_id = data.aws_ssm_parameter.subnet.value
  ecr_url = data.aws_ssm_parameter.ecr.value
}

resource "aws_security_group" "ssh_access" {
  vpc_id      = "${local.vpc_id}"
  name        = "${var.prefix}-ssh_access"
  description = "SSH access group"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP"
    createdBy = "infra-${var.prefix}/news"
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.prefix}-news"
  public_key = "${file("${path.module}/../id_rsa.pub")}"
}

data "aws_ami" "amazon_linux_2" {
 most_recent = true

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }

 filter {
   name = "architecture"
   values = ["x86_64"]
 }

 owners = ["137112412989"] #amazon
}

### Front end

resource "aws_security_group" "front_end_sg" {
  vpc_id      = "${local.vpc_id}"
  name        = "${var.prefix}-front_end"
  description = "Security group for front_end"

  tags = {
    Name = "SG for front_end"
    createdBy = "infra-${var.prefix}/news"
  }
}

# Allow all outbound connections
resource "aws_security_group_rule" "front_end_all_out" {
  type        = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.front_end_sg.id}"
}

resource "aws_instance" "front_end" {
  ami           = "${data.aws_ami.amazon_linux_2.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.ssh_key.key_name}"
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }

  iam_instance_profile = "${var.prefix}_news_host"

  availability_zone = "${var.region}a"

  subnet_id = local.subnet_id

  vpc_security_group_ids = [
    "${aws_security_group.front_end_sg.id}",
    "${aws_security_group.ssh_access.id}"
  ]

  tags = {
    Name = "${var.prefix}-front_end"
    createdBy = "infra-${var.prefix}/news"
  }

  connection {
    host = "${self.public_ip}"
    type = "ssh"
    user = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision-docker.sh"
  }
}

# Allow public access to the front-end server
resource "aws_security_group_rule" "front_end" {
  type        = "ingress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]

  security_group_id = "${aws_security_group.front_end_sg.id}"
}
### end of front-end

resource "aws_security_group" "quotes_sg" {
  vpc_id      = "${local.vpc_id}"
  name        = "${var.prefix}-quotes_sg"
  description = "Security group for quotes"

  tags = {
    Name = "SG for quotes"
    createdBy = "infra-${var.prefix}/news"
  }
}

# Allow all outbound connections
resource "aws_security_group_rule" "quotes_all_out" {
  type        = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.quotes_sg.id}"
}

resource "aws_instance" "quotes" {
  ami           = "${data.aws_ami.amazon_linux_2.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.ssh_key.key_name}"
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }

  iam_instance_profile = "${var.prefix}_news_host"

  availability_zone = "${var.region}a"

  subnet_id = local.subnet_id

  vpc_security_group_ids = [
    "${aws_security_group.quotes_sg.id}",
    "${aws_security_group.ssh_access.id}"
  ]

  tags = {
    Name = "${var.prefix}-quotes"
    createdBy = "infra-${var.prefix}/news"
  }

  connection {
    host = "${self.public_ip}"
    type = "ssh"
    user = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision-docker.sh"
  }
}

# Allow internal access to the quotes HTTP server from front-end
resource "aws_security_group_rule" "quotes_internal_http" {
  type        = "ingress"
  from_port   = 8082
  to_port     = 8082
  protocol    = "tcp"
  source_security_group_id = "${aws_security_group.front_end_sg.id}"
  security_group_id = "${aws_security_group.quotes_sg.id}"
}

resource "null_resource" "quotes_provision" {
  connection {
      host = "${aws_instance.quotes.public_ip}"
      type = "ssh"
      user = "ec2-user"
      private_key = "${file("${path.module}/../id_rsa")}"
  }
  provisioner "file" {
    source = "${path.module}/provision-quotes.sh"
    destination = "/home/ec2-user/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/provision.sh",
      "/home/ec2-user/provision.sh ${local.ecr_url}quotes:latest"
    ]
  }
}

resource "aws_security_group" "newsfeed_sg" {
  vpc_id      = "${local.vpc_id}"
  name        = "${var.prefix}_newsfeed_sg"
  description = "Security group for newsfeed"

  tags = {
    Name = "SG for newsfeed"
    createdBy = "infra-${var.prefix}/news"
  }
}

# Allow all outbound connections
resource "aws_security_group_rule" "newsfeed_all_out" {
  type        = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.newsfeed_sg.id}"
}

resource "aws_instance" "newsfeed" {
  ami           = "${data.aws_ami.amazon_linux_2.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.ssh_key.key_name}"
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }

  iam_instance_profile = "${var.prefix}_news_host"

  availability_zone = "${var.region}a"

  subnet_id = local.subnet_id

  vpc_security_group_ids = [
    "${aws_security_group.newsfeed_sg.id}",
    "${aws_security_group.ssh_access.id}"
  ]

  tags = {
    Name = "${var.prefix}-newsfeed"
    createdBy = "infra-${var.prefix}/news"
  }

  connection {
    host = "${self.public_ip}"
    type = "ssh"
    user = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision-docker.sh"
  }
}

# Allow internal access to the newsfeed HTTP server from front-end
resource "aws_security_group_rule" "newsfeed_internal_http" {
  type        = "ingress"
  from_port   = 8081
  to_port     = 8081
  protocol    = "tcp"
  source_security_group_id = "${aws_security_group.front_end_sg.id}"
  security_group_id = "${aws_security_group.newsfeed_sg.id}"
}

resource "null_resource" "newsfeed_provision" {
  connection {
      host = "${aws_instance.newsfeed.public_ip}"
      type = "ssh"
      user = "ec2-user"
      private_key = "${file("${path.module}/../id_rsa")}"
  }
  provisioner "file" {
    source = "${path.module}/provision-newsfeed.sh"
    destination = "/home/ec2-user/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/provision.sh",
      "/home/ec2-user/provision.sh ${local.ecr_url}newsfeed:latest"
    ]
  }
}

resource "null_resource" "front_end_provision" {
  connection {
      host = "${aws_instance.front_end.public_ip}"
      type = "ssh"
      user = "ec2-user"
      private_key = "${file("${path.module}/../id_rsa")}"
  }
  provisioner "file" {
    source = "${path.module}/provision-front_end.sh"
    destination = "/home/ec2-user/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/provision.sh",
<<EOF
      /home/ec2-user/provision.sh \
      --region ${var.region} \
      --docker-image ${local.ecr_url}front_end:latest \
      --quote-service-url http://${aws_instance.quotes.private_ip}:8082 \
      --newsfeed-service-url http://${aws_instance.newsfeed.private_ip}:8081 \
      --static-url http://${aws_s3_bucket.news.website_endpoint}
EOF
    ]
  }
}

output "frontend_url" {
  value = "http://${aws_instance.front_end.public_ip}:8080"
}
