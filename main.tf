#creating a vpc dev environment

resource "aws_vpc" "dev_env" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "dev"
  }
}

#create a subnet

resource "aws_subnet" "dev_public_subnet" {
  vpc_id                  = aws_vpc.dev_env.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

# create an internet gateway (all of these will be a "resource")

resource "aws_internet_gateway" "dev_internet_gateway" {
  vpc_id = aws_vpc.dev_env.id

  tags = {

    Name = "dev_internetgw"

  }

}

#create a route table. This route table will be public

resource "aws_route_table" "dev_public_rt" {
  vpc_id = aws_vpc.dev_env.id

  tags = {
    "Name" = "dev_publicrt"
  }

}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.dev_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev_internet_gateway.id

}

#create a route table association (associate subnet with route table)

resource "aws_route_table_association" "dev_rtb_association" {
  subnet_id      = aws_subnet.dev_public_subnet.id
  route_table_id = aws_route_table.dev_public_rt.id

}

#create a security group. This security group will have basic public access (copy / paste template via terraform documentation)

resource "aws_security_group" "dev_env_sg" {
  name        = "dev-sg"
  description = "dev security group"
  vpc_id      = aws_vpc.dev_env.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["72.216.81.55/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create ec2 instance with keypair and tag it. 
#add template that installs docker onto the EC2 instance. 

resource "aws_instance" "dev_server" {
  ami                    = "ami-0c4f7023847b90238"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.dev_key.id
  vpc_security_group_ids = [aws_security_group.dev_env_sg.id]
  subnet_id              = aws_subnet.dev_public_subnet.id
  user_data              = templatefile("dockerinstall.tpl", {})

  tags = {
    "Name" = "dev_server"
  }

}

resource "aws_key_pair" "dev_key" {
  key_name   = "devkey1"
  public_key = file("~/.ssh/devkey1.pub")

}
