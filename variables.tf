locals {
  cluster_name    = "main"
  cluster_version = "1.22"
  vpc_id          = "vpc-08ea373114b72653a"
  aws_account_id  = "596734924894"
  aws_region      = "ap-south-1"
  private_subnets = ["subnet-0643093d9edecd561", "subnet-0dd09aca700cc53d3", "subnet-0ed553255e2d5b6bb"]
  sshkeys        = "learnarcab"
}
