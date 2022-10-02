PROJECT_NAME="eks-mumbai-prod1" # use current dir name
AWS_REGION="ap-south-1"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

aws s3api create-bucket \
	--region "${AWS_REGION}" \
	--create-bucket-configuration LocationConstraint="${AWS_REGION}" \
	--bucket "terraform-tfstate-${ACCOUNT_ID}"

aws dynamodb create-table \
	--region "${AWS_REGION}" \
	--table-name terraform_locks \
	--attribute-definitions AttributeName=LockID,AttributeType=S \
	--key-schema AttributeName=LockID,KeyType=HASH \
	--provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1

cat <<EOF > ./backend_config.tf
terraform {
  backend "s3" {
    bucket         = "terraform-tfstate-${ACCOUNT_ID}"
    key            = "${PROJECT_NAME}"
    region         = "${AWS_REGION}"
    lock_table     = "terraform_locks"
  }
}
EOF
