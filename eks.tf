terraform {
  backend "s3" {
    bucket         = "iac-terraform-states-learnarcab-eks"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "iac-terraform-states-lock-eks"
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = local.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.14.0.0/16"
    ]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "cluster_additional_security_group" {
  name_prefix = "cluster_additional_security_group"
  vpc_id      = local.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "10.14.0.0/16"    ]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}




module "eks" {
  source                                = "terraform-aws-modules/eks/aws"
  version                               = "18.11.0"
  cluster_name                          = local.cluster_name
  cluster_version                       = local.cluster_version
  subnet_ids                            = local.private_subnets
  cluster_additional_security_group_ids = [aws_security_group.cluster_additional_security_group.id]
  vpc_id                                = local.vpc_id
  cluster_enabled_log_types             = ["audit"]
  cluster_endpoint_private_access       = true
  cluster_endpoint_public_access        = false
  cluster_addons                        = {}
  iam_role_name                         = local.cluster_name
  iam_role_use_name_prefix              = false
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    disk_size              = 40
    vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]
    bootstrap_extra_args   = "--container-runtime containerd --kubelet-extra-args '--max-pods=20'"
    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
      "arn:aws:iam::${local.aws_account_id}:policy/SecretsManagerReadOnly"
    ]
    remote_access = {
      ec2_ssh_key               = local.sshkeys
      source_security_group_ids = [aws_security_group.all_worker_mgmt.id]
    }
  }

  eks_managed_node_groups = {
    default = {
      min_size               = 2
      max_size               = 2
      desired_size           = 2
      create_launch_template = false
      launch_template_name   = ""
      instance_types         = ["t3a.medium"]
      capacity_type          = "SPOT"
      labels = {
        env  = "stg"
        kind = "default"
      }
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }
      tags = {
        Name    = "${module.eks.cluster_id}-default"
        arcab = "prod"
      }
    }
    shared = {
      min_size               = 2
      max_size               = 5
      desired_size           = 2
      create_launch_template = false
      launch_template_name   = ""
      instance_types         = ["t3a.medium"]
      capacity_type          = "SPOT"
      labels = {
        env  = "stg"
        kind = "shared"
      }
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      tags = {
        Name    = "${module.eks.cluster_id}-shared"
        arcab = "prod"
      }
    }
    memory-intensive = {
      min_size               = 1
      max_size               = 5
      desired_size           = 1
      create_launch_template = false
      launch_template_name   = ""
      instance_types         = ["t3a.large", "m5a.large"]
      capacity_type          = "SPOT"
      labels = {
        env  = "stg"
        kind = "memory-intensive"
      }
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      tags = {
        Name    = "${module.eks.cluster_id}-memory-intensive"
        arcab = "prod"
      }
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
