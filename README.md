# infrastructure
infrastructure

1. First create a s3 bucket and dynamoDB table for state management.
  - ref the s3-dyanmodb-table.sh and
  - make changes to the variable's
      AWS_REGION, ACCOUNT_ID, PROJECT_NAME as per your account
2. in variables.tf provide the details
  - you have to create and pass vpc-id, subnets, ssh keys, vpc-cidr to access the nodes.

3. plan and apply the terraform and this will create a EKS cluster in the private subnet with 3 worker node groups
