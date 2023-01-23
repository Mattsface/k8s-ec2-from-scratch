resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDfthgrIq4tQN2GgaUxbDaVGFHqsdYT1K0B+8PvrHGGhbOgsmpBFmngIfVLSm4VARCfra1di/CmdvA9XU1gTMnZ6j6o3xX4iYEZSyX4twp2RZiFpFfd44EDpw+/dKCgL/csmEqksshE9z3phP9vS3KMbXlLn+6HGhuQjSX3pNi8GhweoYRwAv6hm3PeWyl2l/bAeLKi06yC5Iej3l8OXMOVAcQbi8Y1y7+mQn4tyLl0ORbXdLCRAXqiTwx4pK5JMVZ4ujJLKGz3xxZNgWV4dy9SeNE+FfX/9dSoQUgipJGmyBhPBzYUOq9JPLro2m/oHQOv9psrZXUTSLU1e1gxfgJZsvY+CGwoME4YtTxh7bybk7fzmteluBIhIbYw/hd9/UESFOiLrHi8R30kYsHUsZGiAAivd5qs8gXXkiuSjazds3stLlLDtxGRwo1FeF7VAS+9vlaXgLW9zHZrwZ87ea4JIBDhgnKzyKsvLad7it/UwU+TpCJk6oURwNOF8x0Bb4k/jx3z3fr9IXlbXuQMnsPf1MNI/pUCKSvKBKyxzZQWiHZAFiggk5zPT1UzhLCDyO/lIj3KX5mqyhMobFPDcrhGDukscz6O93+2KRGWxAWN9cr6JpkNMT9PAYcSi+1fUF+0X+aqc5bRJrXBWhPAI5Tw1HrZfpTos+gYPpj/lpb1kQ== mattsface@Matthews-MacBook-Pro.local"
}

# k8s controllers
## k8s controller 1 
resource "aws_network_interface" "k8s-1c" {
  subnet_id   = aws_subnet.k8s-private-1.id
  security_groups = [aws_security_group.k8s-sg.id]

  tags = {
    Name = "controller 1 nwi"
  }
}

resource "aws_instance" "k8s-1c" {
  ami           = "ami-04bad3c587fe60d89" # us-west-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.k8s-1c.id
    device_index         = 0
  }

  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = "controller 1"
  }
}

## k8s controller 2 
resource "aws_network_interface" "k8s-2c" {
  subnet_id   = aws_subnet.k8s-private-1.id
  security_groups = [aws_security_group.k8s-sg.id]

  tags = {
    Name = "controller 2 nwi"
  }
}

resource "aws_instance" "k8s-2c" {
  ami           = "ami-04bad3c587fe60d89" # us-west-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.k8s-2c.id
    device_index         = 0
  }

  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = "controller 2"
  }
}

## k8s controller 3
resource "aws_network_interface" "k8s-3c" {
  subnet_id   = aws_subnet.k8s-private-1.id
  security_groups = [aws_security_group.k8s-sg.id]

  tags = {
    Name = "controller 3 nwi"
  }
}

resource "aws_instance" "k8s-3c" {
  ami           = "ami-04bad3c587fe60d89" # us-west-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.k8s-3c.id
    device_index         = 0
  }

  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = "controller 3"
  }
}