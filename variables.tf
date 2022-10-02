locals {
  cluster_name    = "main"
  cluster_version = "1.22"
  vpc_id          = "vpc-0123xxx456"
  aws_account_id  = "123456789"
  aws_region      = "ap-south-1"
  private_subnets = ["subnet-abcd1234567", "subnet-0198765zxywtsu", "subnet-0sqwsdsdsde2db"]
  sshkeys        = "learna"
}
