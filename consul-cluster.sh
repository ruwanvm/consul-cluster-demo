#!/bin/sh

CURRENT_CONSUL_VERSION=$(cat consul_cluster.version)
cp configurations/consul-server-userdata /tmp/server-userdata
cp configurations/consul-client-userdata /tmp/client-userdata

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
  echo "Error occurred - initializing S3 - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  CONSUL_CONFIG_BUCKET=$(terraform output -raw consul_config_bucket)
  cd ../
  pwd
  aws s3 cp ../configurations/consul-server-userdata s3://"${CONSUL_CONFIG_BUCKET}"/templates/server/userdata --profile "${AWS_PROFILE}"
  aws s3 cp ../configurations/consul-client-userdata s3://"${CONSUL_CONFIG_BUCKET}"/templates/client/userdata --profile "${AWS_PROFILE}"
  aws s3 cp ../configurations/server_config.json s3://"${CONSUL_CONFIG_BUCKET}"/templates/server/server_config.json --profile "${AWS_PROFILE}"
  aws s3 cp ../configurations/client_config.json s3://"${CONSUL_CONFIG_BUCKET}"/templates/client/client_config.json --profile "${AWS_PROFILE}"
  echo "----------------------------------------------------------------------"
  echo "Configuration bucket of Consul cluster is checked"
  echo "----------------------------------------------------------------------"
else
  echo "Error occurred - configuring S3 - Check output above"
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
  echo "Error occurred - finalize S3 - Check output above"
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

# Create Consul leader
if [ $? -eq 0 ]; then
  echo "----------------------------------------------------------------------"
  echo "Creating consul leader"
  echo "----------------------------------------------------------------------"
  cd consul-leader
  terraform init \
    -backend-config="bucket=${TF_BACKEND_BUCKET}" \
    -backend-config="region=${TF_BACKEND_REGION}" \
    -backend-config="profile=${TF_BACKEND_PROFILE}" \
    -backend-config="key=aws/consul-cluster/consul-leader/terraform.tfstate"
else
  echo "Error occurred - Check output above"
  exit 1
fi

if [ $? -eq 0 ]; then
  terraform fmt
  terraform apply \
    -var "aws_profile=${AWS_PROFILE}" \
    -var "aws_region=${AWS_REGION}" \
    -var "keypair_id=${KEYPAIR_ID}" \
    -var "security_group=${SECURITY_GROUP_ID}" \
    -var "subnet_id=${SUBNET_ID_1}" \
    -var "iam_instance_profile=${IAM_INSTANCE_PROFILE}" \
    -var "consul_ami_id=${AMI_ID}" \
    -var "consul_bucket=${CONSUL_CONFIG_BUCKET}" \
    -auto-approve
else
  echo "Error occurred - initializing Consul leader - Check output above"
  exit 1
fi
if [ $? -eq 0 ]; then
  CONSUL_LEADER_IP=$(terraform output -raw leader_ip)
  echo "----------------------------------------------------------------------"
  echo "Consul leader started ${CONSUL_LEADER_IP}:8500"
  echo "----------------------------------------------------------------------"
  cd ../
else
  echo "Error occurred - configuring Consul leader - Check output above"
  exit 1
fi

# Create Launch Configurations, Auto Scaling Groups
echo "----------------------------------------------------------------------"
echo "Creating Consul Cluster"
echo "----------------------------------------------------------------------"

if [ $? -eq 0 ]; then
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
  cd ../..
  echo "======================================================================"
  echo "Consul Cluster is created with version ${NEW_CONSUL_VERSION}"
  echo "Consul UI : http://${CONSUL_LEADER_IP}:8500/ui"
  echo "======================================================================"
  echo "${NEW_CONSUL_VERSION}">consul_cluster.version
else
  echo "Error occurred - Creating Consul cluster - check output above"
  exit 1
fi