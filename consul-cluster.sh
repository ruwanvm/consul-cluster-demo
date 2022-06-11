#!/bin/sh

CURRENT_CONSUL_VERSION=$(cat consul_cluster.version)
CONSUL_VERSION_CHANGE=0
if [ "$CURRENT_CONSUL_VERSION" = "0.00.0" ]; then
  echo "######################################################################"
  echo "Consul cluster not running"
  echo "######################################################################"
else
  echo "######################################################################"
  echo "Consul cluster running with ${CURRENT_CONSUL_VERSION}"
  echo "######################################################################"
fi
echo "----------------------------------------------------------------------"
read -p "Consul version: " NEW_CONSUL_VERSION
echo "----------------------------------------------------------------------"
if [ "$CURRENT_CONSUL_VERSION" != "$NEW_CONSUL_VERSION" ]; then
  CONSUL_VERSION_CHANGE=1
fi

cd infrastructure

# Create VCP and Subnets (Network) for Consul cluster
if [ $? -eq 0 ]; then
  echo "----------------------------------------------------------------------"
  echo "Check network components of Consul cluster"
  echo "----------------------------------------------------------------------"
  cd vpc/
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/vpc/terraform.tfstate"
else
  echo "Error occurred - checking consul version - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform fmt
  terraform apply \
    -var "aws_profile=${AWS_PROFILE}" \
    -var "aws_region=${AWS_REGION}" \
    -auto-approve
else
  echo "Error occurred - initializing network - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  VPC_ID=$(terraform output -raw consul_vpc_id)
  SUBNET_ID_1=$(terraform output -raw consul_subnet_1_id)
  SUBNET_ID_2=$(terraform output -raw consul_subnet_2_id)
  SUBNET_ID_3=$(terraform output -raw consul_subnet_3_id)
  echo "----------------------------------------------------------------------"
  echo "Network components of Consul cluster are checked"
  echo "----------------------------------------------------------------------"
  cd ../
else
  echo "Error occurred - configuring network - Check output above"
  exit 1
fi

# Create IAM Role for Consul cluster
if [ $? -eq 0 ]; then
  echo "----------------------------------------------------------------------"
  echo "Check IAM configuration for Consul cluster instances"
  echo "----------------------------------------------------------------------"
  cd iam/
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/iam/terraform.tfstate"
else
  echo "Error occurred - finalize network - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform fmt
  terraform apply \
    -var "aws_profile=${AWS_PROFILE}" \
    -var "aws_region=${AWS_REGION}" \
    -var "consul_config_s3_bucket=${CONSUL_CONFIG_BUCKET}" \
    -auto-approve
else
  echo "Error occurred - initializing IAM - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  IAM_INSTANCE_PROFILE=$(terraform output -raw consul_instance_profile_name)
  echo "----------------------------------------------------------------------"
  echo "IAM Configuration of Consul cluster instances is checked"
  echo "----------------------------------------------------------------------"
  cd ../
else
  echo "Error occurred - configuring IAM - Check output above"
  exit 1
fi

# Create KeyPair and Security Groups for Consul cluster
if [ $? -eq 0 ]; then
  echo "----------------------------------------------------------------------"
  echo "Check EC2 configuration for Consul cluster instances"
  echo "----------------------------------------------------------------------"
  cd ec2/
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/ec2/terraform.tfstate"
else
  echo "Error occurred - finalize IAM - output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform fmt
  terraform apply \
    -var "aws_profile=${AWS_PROFILE}" \
    -var "aws_region=${AWS_REGION}" \
    -var "consul_vpc_id=${VPC_ID}" \
    -auto-approve
else
  echo "Error occurred - initializing EC2 - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  KEYPAIR_ID=$(terraform output -raw consul_keypair)
  SECURITY_GROUP_ID=$(terraform output -raw consul_server_security_group)
  CONSUL_LEADER_IP=$(terraform output -raw leader_ip)
  echo "----------------------------------------------------------------------"
  echo "EC2 Configuration of Consul cluster instances is checked"
  echo "----------------------------------------------------------------------"
  cd ../
else
  echo "Error occurred - configuring EC2 - Check output above"
  exit 1
fi

# Create AMI with Consul version
if [ "$CURRENT_CONSUL_VERSION" != "$NEW_CONSUL_VERSION" ]; then
  echo "----------------------------------------------------------------------"
  echo "Update Consul AMI ${NEW_CONSUL_VERSION}"
  echo "----------------------------------------------------------------------"
  cd consul-ami/
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/consul-ami/terraform.tfstate"
  if [ $? -eq 0 ]; then
    terraform fmt
    terraform apply \
      -var "aws_profile=${AWS_PROFILE}" \
      -var "aws_region=${AWS_REGION}" \
      -var "keypair_id=${KEYPAIR_ID}" \
      -var "security_group=${SECURITY_GROUP_ID}" \
      -var "subnet_id=${SUBNET_ID_1}" \
      -var "iam_instance_profile=${IAM_INSTANCE_PROFILE}" \
      -var "consul_version=${NEW_CONSUL_VERSION}" \
      -auto-approve
  else
    echo "Error occurred - initializing AMI - Check output above"
    exit 1
  fi
  if [ $? -eq 0 ]; then
    AMI_ID=$(terraform output -raw consul_ami_id)
  else
    echo "Error occurred - configuring AMI - output above"
    exit 1
  fi
  if [ $? -eq 0 ]; then
    echo "----------------------------------------------------------------------"
    echo "Consul AMI is created"
    echo "----------------------------------------------------------------------"
    cd ../
  else
    echo "Error occurred - finalize AMI - Check output above"
    exit 1
  fi
else
  echo "----------------------------------------------------------------------"
  echo "Consul AMI with version ${NEW_CONSUL_VERSION} is already running"
  echo "----------------------------------------------------------------------"
  cd consul-ami/
  terraform fmt
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/consul-ami/terraform.tfstate"
  if [ $? -eq 0 ]; then
    AMI_ID=$(terraform output -raw consul_ami_id)
  else
    echo "Error occurred - initializing AMI - check output above"
    exit 1
  fi
  if [ $? -eq 0 ]; then
    cd ../
  else
    echo "Error occurred - getting AMI ID - check output above"
    exit 1
  fi
fi

# Create Leader network
if [ $? -eq 0 ]; then
  echo "----------------------------------------------------------------------"
  echo "Creating Consul Leader network"
  echo "----------------------------------------------------------------------"
  pwd
  cd consul-leaders
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/consul-leader/terraform.tfstate"
else
  echo "Error occurred - configuring userdata - Check output above"
  exit 1
fi
if [ $CONSUL_VERSION_CHANGE -gt 0 ]; then
    terraform fmt
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
fi
if [ $? -eq 0 ]; then
    terraform fmt
    terraform apply \
      -var "aws_profile=${AWS_PROFILE}" \
      -var "aws_region=${AWS_REGION}" \
      -var "consul_ami_id=${AMI_ID}" \
      -var "security_group=${SECURITY_GROUP_ID}" \
      -var "iam_instance_profile=${IAM_INSTANCE_PROFILE}" \
      -var "keypair_id=${KEYPAIR_ID}" \
      -var "subnet_id_1=${SUBNET_ID_1}" \
      -var "subnet_id_2=${SUBNET_ID_2}" \
      -var "subnet_id_3=${SUBNET_ID_3}" \
      -var "leader_public_ip=${CONSUL_LEADER_IP}" \
      -auto-approve
else
  echo "Error occurred - initializing Consul cluster - check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  echo "----------------------------------------------------------------------"
  echo "Consul AMI is created"
  echo "----------------------------------------------------------------------"
  cd ../
else
  echo "Error occurred - finalize AMI - Check output above"
  exit 1
fi


# Create Launch Configurations, Auto Scaling Groups
if [ $? -eq 0 ]; then
  echo "----------------------------------------------------------------------"
  echo "Creating Consul Cluster"
  echo "----------------------------------------------------------------------"
  cd consul-cluster
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/consul-cluster/terraform.tfstate"
else
  echo "Error occurred - configuring userdata - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
    terraform fmt
    terraform apply \
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

if [ $? -eq 0 ]; then
  SERVER_AUTOSCALE=$(terraform output -raw consul_server_autoscale_group)
  CLIENT_AUTOSCALE=$(terraform output -raw consul_client_autoscale_group)
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "${SERVER_AUTOSCALE}" --desired-capacity 6 --profile "${AWS_PROFILE}"
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "${CLIENT_AUTOSCALE}" --desired-capacity 6 --profile "${AWS_PROFILE}"
  echo "waiting for Autoscaling to be completed ..."
  sleep 60
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "${SERVER_AUTOSCALE}" --desired-capacity 3 --profile "${AWS_PROFILE}"
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "${CLIENT_AUTOSCALE}" --desired-capacity 3 --profile "${AWS_PROFILE}"
  cd ../..
  echo "======================================================================"
  echo "Consul Cluster is created with version ${NEW_CONSUL_VERSION}"
  echo "Consul UI : http://${CONSUL_LEADER_IP}:8500/ui" # Add ELB and attach to server Autoscale group use hostname here
  echo "======================================================================"
  echo "${NEW_CONSUL_VERSION}">consul_cluster.version
else
  echo "Error occurred - Creating Consul cluster - check output above"
  exit 1
fi


# Improvements
# 1. Attach Load balancer to Auto scale group