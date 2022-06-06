#!/bin/sh

CURRENT_CONSUL_VERSION=`cat consul_cluster.version`

if [ "${CURRENT_CONSUL_VERSION}" == "0.00.0" ]; then
  echo "######################################################################"
  echo "Consul cluster not running"
  echo "######################################################################"
else
  echo "######################################################################"
  echo "Consul cluster running with ${CURRENT_CONSUL_VERSION}"
  echo "######################################################################"
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
  echo "Error occurred - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform apply -var "aws_profile=${AWS_PROFILE}" -var "aws_region=${AWS_REGION}" -auto-approve
else
  echo "Error occurred - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  VPC_ID=`terraform output -raw consul_vpc_id`
  SUBNET_ID_1=`terraform output -raw consul_subnet_1_id`
  SUBNET_ID_2=`terraform output -raw consul_subnet_2_id`
  SUBNET_ID_3=`terraform output -raw consul_subnet_3_id`
  echo "----------------------------------------------------------------------"
  echo "Network components of Consul cluster are checked"
  echo "----------------------------------------------------------------------"
  cd ../
else
  echo "Error occurred - Check output above"
  exit 1
fi

# Create Consul Configs S3 bucket
if [ $? -eq 0 ]; then
  echo "----------------------------------------------------------------------"
  echo "Check configuration bucket for Consul cluster"
  echo "----------------------------------------------------------------------"
  cd s3/
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/s3/terraform.tfstate"
else
  echo "Error occurred - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform apply -var "aws_profile=${AWS_PROFILE}" -var "aws_region=${AWS_REGION}" -var "consul_config_s3_bucket=${CONSUL_CONFIG_BUCKET}" -auto-approve
else
  echo "Error occurred - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  CONSUL_CONFIG_BUCKET=`terraform output -raw consul_config_bucket`
  echo "----------------------------------------------------------------------"
  echo "Configuration bucket of Consul cluster is checked"
  echo "----------------------------------------------------------------------"
  cd ../
else
  echo "Error occurred - Check output above"
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
  echo "Error occurred - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  terraform apply -var "aws_profile=${AWS_PROFILE}" -var "aws_region=${AWS_REGION}" -var "consul_config_s3_bucket=${CONSUL_CONFIG_BUCKET}" -auto-approve
else
  echo "Error occurred - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  IAM_INSTANCE_PROFILE=`terraform output -raw consul_instance_profile_name`
  echo "----------------------------------------------------------------------"
  echo "IAM Configuration of Consul cluster instances is checked"
  echo "----------------------------------------------------------------------"
  cd ../
else
  echo "Error occurred - Check output above"
  exit 1
fi

# Create KeyPair and Security Groups for Consul cluster

# Create AMI with Consul version

# Create Consul Config for Consul cluster

# Create Launch Template, Auto Scaling Group and Load Balances
