#!/bin/sh

CURRENT_CONSUL_VERSION=$(cat consul_cluster.version)

if [ "$CURRENT_CONSUL_VERSION" = "0.00.0" ]; then
  echo "######################################################################"
  echo "Consul cluster not running"
  echo "######################################################################"
  exit 0
else
  echo "######################################################################"
  echo "Destroying Consul cluster running with ${CURRENT_CONSUL_VERSION}"
  echo "######################################################################"
fi

cd infrastructure

# Get Parameters
#-------#
cd vpc
terraform init \
  -backend-config="bucket=${TF_BACKEND_BUCKET}" \
  -backend-config="region=${TF_BACKEND_REGION}" \
  -backend-config="profile=${TF_BACKEND_PROFILE}" \
  -backend-config="key=aws/consul-cluster/vpc/terraform.tfstate"
VPC_ID=$(terraform output -raw consul_vpc_id)
SUBNET_ID_1=$(terraform output -raw consul_subnet_1_id)
SUBNET_ID_2=$(terraform output -raw consul_subnet_2_id)
SUBNET_ID_3=$(terraform output -raw consul_subnet_3_id)
cd ../
#-------#
cd iam
terraform init \
  -backend-config="bucket=${TF_BACKEND_BUCKET}" \
  -backend-config="region=${TF_BACKEND_REGION}" \
  -backend-config="profile=${TF_BACKEND_PROFILE}" \
  -backend-config="key=aws/consul-cluster/iam/terraform.tfstate"
IAM_INSTANCE_PROFILE=$(terraform output -raw consul_instance_profile_name)
cd ../
#-------#
cd ec2
terraform init \
  -backend-config="bucket=${TF_BACKEND_BUCKET}" \
  -backend-config="region=${TF_BACKEND_REGION}" \
  -backend-config="profile=${TF_BACKEND_PROFILE}" \
  -backend-config="key=aws/consul-cluster/ec2/terraform.tfstate"
KEYPAIR_ID=$(terraform output -raw consul_keypair)
SECURITY_GROUP_ID=$(terraform output -raw consul_server_security_group)
CONSUL_LEADER_IP=$(terraform output -raw leader_ip)
cd ../
#-------#
cd consul-ami
terraform init \
  -backend-config="bucket=${TF_BACKEND_BUCKET}" \
  -backend-config="region=${TF_BACKEND_REGION}" \
  -backend-config="profile=${TF_BACKEND_PROFILE}" \
  -backend-config="key=aws/consul-cluster/consul-ami/terraform.tfstate"
AMI_ID=$(terraform output -raw consul_ami_id)
cd ../
#-------#
cd consul-ami
terraform init \
  -backend-config="bucket=${TF_BACKEND_BUCKET}" \
  -backend-config="region=${TF_BACKEND_REGION}" \
  -backend-config="profile=${TF_BACKEND_PROFILE}" \
  -backend-config="key=aws/consul-cluster/consul-ami/terraform.tfstate"
AMI_ID=$(terraform output -raw consul_ami_id)
#-------#

# Destroy Autoscaling groups and Launch configurations
if [ $? -eq 0 ]; then
  cd ../
  echo "----------------------------------------------------------------------"
  echo "Destroy Consul Cluster - Auto scale groups and Launch templates"
  echo "----------------------------------------------------------------------"
  cd consul-cluster
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/consul-cluster/terraform.tfstate"
else
  echo "Error occurred - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform destroy \
    -var "aws_profile=${AWS_PROFILE}" \
    -var "aws_region=${AWS_REGION}" \
    -var "keypair_id=${KEYPAIR_ID}" \
    -var "security_group=${SECURITY_GROUP_ID}" \
    -var "subnet_id_1=${SUBNET_ID_1}" \
    -var "subnet_id_2=${SUBNET_ID_2}" \
    -var "subnet_id_3=${SUBNET_ID_3}" \
    -var "iam_instance_profile=${IAM_INSTANCE_PROFILE}" \
    -var "consul_ami_id=${AMI_ID}" \
    -var "consul_bucket=${CONSUL_CONFIG_BUCKET}" \
    -var "consul_version=${NEW_CONSUL_VERSION}" \
    -auto-approve
else
  echo "Error occurred - initializing Consul cluster - check output above"
  exit 1
fi

# Destroy Consul-leader network
if [ $? -eq 0 ]; then
  cd ../
  echo "----------------------------------------------------------------------"
  echo "Destroy Consul Cluster - Leader Network"
  echo "----------------------------------------------------------------------"
  cd consul-leaders
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/consul-leader/terraform.tfstate"
else
  echo echo "Error occurred - destroying Consul cluster - check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform destroy \
    -var "aws_profile=${AWS_PROFILE}" \
    -var "aws_region=${AWS_REGION}" \
    -var "consul_ami_id=${AMI_ID}" \
    -var "security_group=${SECURITY_GROUP_ID}" \
    -var "iam_instance_profile=${IAM_INSTANCE_PROFILE}" \
    -var "keypair_id=${KEYPAIR_ID}" \
    -var "subnet_id_1=${SUBNET_ID_1}" \
    -var "subnet_id_2=${SUBNET_ID_2}" \
    -var "subnet_id_3=${SUBNET_ID_3}" \
    -var "leader_public_ip=${LEADER_IP}" \
    -auto-approve
else
  echo "Error occurred - initializing consul leader network - check output above"
  exit 1
fi

# Destroy Consul AMI resources
if [ $? -eq 0 ]; then
  cd ../
  echo "----------------------------------------------------------------------"
  echo "Destroy Consul Cluster - AMI Resources"
  echo "----------------------------------------------------------------------"
  cd consul-ami
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/consul-ami/terraform.tfstate"
else
  echo echo "Error occurred - destroying consul leader network - check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform destroy \
    -var "aws_profile=${AWS_PROFILE}" \
    -var "aws_region=${AWS_REGION}" \
    -var "keypair_id=${KEYPAIR_ID}" \
    -var "security_group=${SECURITY_GROUP_ID}" \
    -var "subnet_id=${SUBNET_ID_1}" \
    -var "iam_instance_profile=${IAM_INSTANCE_PROFILE}" \
    -var "consul_version=${NEW_CONSUL_VERSION}" \
    -auto-approve
else
  echo "Error occurred - initializing consul ami resources - check output above"
  exit 1
fi

# Destroy Keypair and Security group
if [ $? -eq 0 ]; then
  cd ../
  echo "----------------------------------------------------------------------"
  echo "Destroy Consul Cluster - EC2 Resources"
  echo "----------------------------------------------------------------------"
  cd ec2/
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/ec2/terraform.tfstate"
else
  echo echo "Error occurred - destroying consul ami resources - check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform destroy \
    -var "aws_profile=${AWS_PROFILE}" \
    -var "aws_region=${AWS_REGION}" \
    -var "consul_vpc_id=${VPC_ID}" \
    -auto-approve
else
  echo "Error occurred - initializing consul ec2 resources (Keypair & Security Group) - check output above"
  exit 1
fi

# Destroy IAM role
if [ $? -eq 0 ]; then
  cd ../
  echo "----------------------------------------------------------------------"
  echo "Destroy Consul Cluster - IAM Resources"
  echo "----------------------------------------------------------------------"
  cd iam/
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/iam/terraform.tfstate"
else
  echo echo "Error occurred - destroying consul ec2 resources - check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform destroy \
    -var "aws_profile=${AWS_PROFILE}" \
    -var "aws_region=${AWS_REGION}" \
    -var "consul_config_s3_bucket=${CONSUL_CONFIG_BUCKET}" \
    -auto-approve
else
  echo "Error occurred - initializing consul iam resources - check output above"
  exit 1
fi

# Destroy VPC & Subnet components
if [ $? -eq 0 ]; then
  cd ../
  echo "----------------------------------------------------------------------"
  echo "Destroy Consul Cluster - VPC Resources"
  echo "----------------------------------------------------------------------"
  cd vpc/
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/vpc/terraform.tfstate"
else
  echo echo "Error occurred - destroying consul iam resources - check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform destroy \
    -var "aws_profile=${AWS_PROFILE}" \
    -var "aws_region=${AWS_REGION}" \
    -auto-approve
else
  echo "Error occurred - initializing consul vpc resources - check output above"
  exit 1
fi

# Finalize Destruction
if [ $? -eq 0 ]; then
  cd ../../
  echo "----------------------------------------------------------------------"
  echo "Destroy Consul Cluster - Success"
  echo "----------------------------------------------------------------------"
  echo "0.00.0">consul_cluster.version
else
  echo "Error occurred - destroying consul vpc resources - check output above"
  exit 1
fi