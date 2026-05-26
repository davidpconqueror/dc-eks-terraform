provider "aws" {
  region = "ap-south-1"
}

# 1. VPC Configuration
resource "aws_vpc" "techpilotz_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "techpilotz-vpc"
  }
}

# 2. Subnet Configurations (2 Subnets for High Availability required by EKS)
resource "aws_subnet" "techpilotz_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.techpilotz_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.techpilotz_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "techpilotz-subnet-${count.index}"
  }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "techpilotz_igw" {
  vpc_id = aws_vpc.techpilotz_vpc.id

  tags = {
    Name = "techpilotz-igw"
  }
}

# 4. Route Table Configuration
resource "aws_route_table" "techpilotz_route_table" {
  vpc_id = aws_vpc.techpilotz_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.techpilotz_igw.id
  }

  tags = {
    Name = "techpilotz-route-table"
  }
}

# 5. Route Table Associations
resource "aws_route_table_association" "techpilotz_association" {
  count          = 2
  subnet_id      = aws_subnet.techpilotz_subnet[count.index].id
  route_table_id = aws_route_table.techpilotz_route_table.id
}

# 6. EKS Cluster Security Group
resource "aws_security_group" "techpilotz_cluster_sg" {
  name        = "techpilotz-cluster-sg"
  vpc_id      = aws_vpc.techpilotz_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "techpilotz-cluster-sg"
  }
}

# 7. Worker Node Security Group
resource "aws_security_group" "techpilotz_node_sg" {
  name        = "techpilotz-node-sg"
  vpc_id      = aws_vpc.techpilotz_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "techpilotz-node-sg"
  }
}

# 8. EKS Cluster Control Plane
resource "aws_eks_cluster" "techpilotz" {
  name     = "techpilotz-cluster"
  role_arn = aws_iam_role.techpilotz_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.techpilotz_subnet[*].id
    security_group_ids = [aws_security_group.techpilotz_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.techpilotz_cluster_role_policy
  ]
}

# 9. EKS Managed Node Group (Corrected for Free Tier & Remote Security Groups)
resource "aws_eks_node_group" "techpilotz" {
  cluster_name    = aws_eks_cluster.techpilotz.name
  node_group_name = "techpilotz-node-group"
  node_role_arn   = aws_iam_role.techpilotz_node_group_role.arn
  subnet_ids      = aws_subnet.techpilotz_subnet[*].id

  scaling_config {
    desired_size = 2   # Optimized to 2 nodes to stay safely within Free Tier limits
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.micro"]  # Fixed: Eligible Free Tier instance type

  remote_access {
    ec2_ssh_key = var.ssh_key_name
    # Fixed: Removed circular source_security_group_ids referencing to avoid AWS API rejection
  }

  depends_on = [
    aws_iam_role_policy_attachment.techpilotz_node_group_role_policy,
    aws_iam_role_policy_attachment.techpilotz_node_group_cni_policy,
    aws_iam_role_policy_attachment.techpilotz_node_group_registry_policy,
    aws_iam_role_policy_attachment.techpilotz_node_group_ebs_policy
  ]
}

# 10. IAM Role for Cluster Control Plane
resource "aws_iam_role" "techpilotz_cluster_role" {
  name = "techpilotz-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "techpilotz_cluster_role_policy" {
  role       = aws_iam_role.techpilotz_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# 11. IAM Role for Managed Worker Nodes
resource "aws_iam_role" "techpilotz_node_group_role" {
  name = "techpilotz-node-group-role"

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

resource "aws_iam_role_policy_attachment" "techpilotz_node_group_role_policy" {
  role       = aws_iam_role.techpilotz_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "techpilotz_node_group_cni_policy" {
  role       = aws_iam_role.techpilotz_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "techpilotz_node_group_registry_policy" {
  role       = aws_iam_role.techpilotz_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "techpilotz_node_group_ebs_policy" {
  role       = aws_iam_role.techpilotz_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
