provider "aws" {
    region = var.region
}

resource "aws_vpc" "particle41VPC" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "publicSubnetA" {
  vpc_id     = aws_vpc.particle41VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "publicSubnetB" {
  vpc_id     = aws_vpc.particle41VPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "privateSubnetA" {
  vpc_id     = aws_vpc.particle41VPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}
resource "aws_subnet" "privateSubnetB" {
  vpc_id     = aws_vpc.particle41VPC.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.particle41VPC.id
}

resource "aws_eip" "nat_eip" {}

resource "aws_nat_gateway" "nat_gw" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.publicSubnetA.id
}

resource "aws_route_table" "publicRouteTable" {
    vpc_id = aws_vpc.particle41VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table" "privateRouteTable" {
    vpc_id = aws_vpc.particle41VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw.id
    }
}

resource "aws_route_table_association" "publicRouteTableAssociationA" {
    subnet_id = aws_subnet.publicSubnetA.id
    route_table_id = aws_route_table.publicRouteTable.id
}

resource "aws_route_table_association" "publicRouteTableAssociationB" {
    subnet_id = aws_subnet.publicSubnetB.id
    route_table_id = aws_route_table.publicRouteTable.id
}

resource "aws_route_table_association" "privateRouteTableAssociationA" {
    subnet_id = aws_subnet.privateSubnetA.id
    route_table_id = aws_route_table.privateRouteTable.id
}

resource "aws_route_table_association" "privateRouteTableAssociationB" {
    subnet_id = aws_subnet.privateSubnetB.id
    route_table_id = aws_route_table.privateRouteTable.id
}

resource "aws_security_group" "ALBSG" {
    vpc_id = aws_vpc.particle41VPC.id
    name = "ALBSG"
    
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "ECSSG" {
    vpc_id = aws_vpc.particle41VPC.id
    name = "ECSSG"

    ingress {
        from_port = var.container_port
        to_port = var.container_port
        protocol = "tcp"
        security_groups = [aws_security_group.ALBSG.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_ecs_cluster" "this" {
    name = var.app_name
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
    name = "${var.app_name}-ecsTaskExecutionRole"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect = "Allow"
          Principal = { Service = "ecs-tasks.amazonaws.com" }
          Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ecsPolicy" {
    role = aws_iam_role.ecsTaskExecutionRole.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "alb" {
    name = "${var.app_name}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.ALBSG.id]
    subnets = [aws_subnet.publicSubnetA.id, aws_subnet.publicSubnetB.id]
}

resource "aws_lb_listener" "albListener" {
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
       target_group_arn = aws_lb_target_group.albTargetGroup.arn
    }
}
resource "aws_lb_target_group" "albTargetGroup" {
    port = var.container_port
    protocol = "HTTP"
        vpc_id = aws_vpc.particle41VPC.id
        target_type = "ip"
}

resource "aws_ecs_task_definition" "this" {
    family = var.app_name
    requires_compatibilities = ["FARGATE"]

    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"
    execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn

    container_definitions = jsonencode([
    {
      name  = var.app_name
      image = var.image

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "this" { 
    name = var.app_name
    cluster = aws_ecs_cluster.this.id
    task_definition = aws_ecs_task_definition.this.arn
    desired_count = 1
    launch_type = "FARGATE"
    network_configuration {
        subnets = [aws_subnet.privateSubnetA.id, aws_subnet.privateSubnetB.id]
        security_groups = [aws_security_group.ECSSG.id]
    }
    load_balancer {
        target_group_arn = aws_lb_target_group.albTargetGroup.arn
        container_name = var.app_name
        container_port = var.container_port
    }
}

