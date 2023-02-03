# k8s VPC 
resource "aws_vpc" "k8s-vpc-main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "kubernetes-from-scratch"
  }
}

# k8s private subnet
resource "aws_subnet" "k8s-private-1" {
  vpc_id     = aws_vpc.k8s-vpc-main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a" # change to a var
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-private-1"
  }
}

# k8s internet gateway
resource "aws_internet_gateway" "k8s-igw" {
  vpc_id = aws_vpc.k8s-vpc-main.id

  tags = {
    Name = "k8s-igw"
  }
}

# k8s route table
resource "aws_route_table" "k8s-rt" {
  vpc_id = aws_vpc.k8s-vpc-main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s-igw.id
  }

  route {    
    cidr_block = "10.200.0.0/24"
    network_interface_id = aws_network_interface.k8s-0w.id
  }

  route {
    cidr_block = "10.200.1.0/24"
    network_interface_id = aws_network_interface.k8s-1w.id
  }

  route {
    cidr_block = "10.200.2.0/24"
    network_interface_id = aws_network_interface.k8s-2w.id
  }

  tags = {
    Name = "k8s-rt"
  }
}

# k8s rt association
resource "aws_route_table_association" "k8s-private-1-rta" {
  subnet_id      = aws_subnet.k8s-private-1.id
  route_table_id = aws_route_table.k8s-rt.id
}

# k8s security group
resource "aws_security_group" "k8s-sg" {
  name        = "k8s-sg"
  description = "allow k8s traffic"
  vpc_id      = aws_vpc.k8s-vpc-main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "nginx from VPC"
    from_port        = 30080
    to_port          = 30080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "ICMP from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "traffic from 10.0.0.0/16"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["10.0.0.0/16"]
  }

  ingress {
    description      = "traffic from 10.200.0.0/16"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["10.200.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow k8s traffic"
  }
}

# ELBv2 k8s
resource "aws_lb" "k8s-nlb" {
  name               = "k8s-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.k8s-private-1.id]

  enable_deletion_protection = false

  tags = {
    Environment = "k8s-nlb"
  }
}

resource "aws_lb" "k8s-nginx-ingress" {
  name               = "k8s-nginx-ingress"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.k8s-private-1.id]

  enable_deletion_protection = false

  tags = {
    Environment = "k8s-nginx-ingress"
  }
}

# k8s target group
resource "aws_lb_target_group" "k8s-tg" {
  name     = "k8s-tg"
  port     = 6443
  protocol = "TCP"
  target_type = "ip"
  vpc_id   = aws_vpc.k8s-vpc-main.id
}

# k8s-nginx-ingress target group
resource "aws_lb_target_group" "k8s-nginx-ingress-tg" {
  name     = "k8s-nginx-ingress-tg"
  port     = 30080
  protocol = "TCP"
  target_type = "ip"
  vpc_id   = aws_vpc.k8s-vpc-main.id
}

# k8s targets
## k8s controller 1 
resource "aws_lb_target_group_attachment" "k8s-c1" {
  target_group_arn = aws_lb_target_group.k8s-tg.arn
  target_id        = "10.0.1.10"
  port             = 6443
}
## k8s controller 2
resource "aws_lb_target_group_attachment" "k8s-c2" {
  target_group_arn = aws_lb_target_group.k8s-tg.arn
  target_id        = "10.0.1.11"
  port             = 6443
}
## k8s controller 3
resource "aws_lb_target_group_attachment" "k8s-c3" {
  target_group_arn = aws_lb_target_group.k8s-tg.arn
  target_id        = "10.0.1.12"
  port             = 6443
}

# k8s-nginx-ingress targets
## k8s worker 0
resource "aws_lb_target_group_attachment" "k8s-nginx-w0" {
  target_group_arn = aws_lb_target_group.k8s-nginx-ingress-tg.arn
  target_id        = "10.0.1.20"
  port             = 30080
}
## k8s worker 1
resource "aws_lb_target_group_attachment" "k8s-nginx-w1" {
  target_group_arn = aws_lb_target_group.k8s-nginx-ingress-tg.arn
  target_id        = "10.0.1.21"
  port             = 30080
}
## k8s worker 2
resource "aws_lb_target_group_attachment" "k8s-nginx-w2" {
  target_group_arn = aws_lb_target_group.k8s-nginx-ingress-tg.arn
  target_id        = "10.0.1.22"
  port             = 30080
}

# k8s nlb listener
resource "aws_alb_listener" "k8s-nginx-listener" {
  default_action {
    target_group_arn = "${aws_lb_target_group.k8s-nginx-ingress-tg.arn}"
    type = "forward"
  }
  load_balancer_arn = "${aws_lb.k8s-nginx-ingress.arn}"
  port = 443
  protocol = "TCP"
}

# k8s nlb listener
resource "aws_alb_listener" "k8s-nlb-listener" {
  default_action {
    target_group_arn = "${aws_lb_target_group.k8s-tg.arn}"
    type = "forward"
  }
  load_balancer_arn = "${aws_lb.k8s-nlb.arn}"
  port = 443
  protocol = "TCP"
}