# Consul Cluster on EC2 instances with Auto Scaling

### Pre requisites

1. Setup Terraform and Ansible on the platform
2. Create S3 bucket for Terraform backend status files
3. Following Environment Variables need to be setup
   * TF_BACKEND_BUCKET - S3 bucket name created for Terraform backend configurations
   * TF_BACKEND_REGION - Region of the bucket
   * TF_BACKEND_PROFILE - AWS profile used to access terraform backend bucket
   * AWS_PROFILE - AWS profile used by Terraform to provision resources
   * AWS_REGION - AWS region, where terraform resources are provisioning
   * CONSUL_CONFIG_BUCKET - Name for S3 bucket use to store consul configurations (Bucket will be created by Terraform)

### Setup and Maintenance

1. Run the script ./consul-cluster.sh
2. It will ask the consul version to be setup (Enter the value)
   ```
   ----------------------------------------------------------------------
   Consul version: x.xx.x
   ----------------------------------------------------------------------
   ```
3. Following infrastructure will be provision in order to start the cluster
   * VPC
   * 3 Public Subnets (In this case I use public subnets as they are easy to manage and low cost)
   * Internet Gateway
   * S3 bucket - This will be used to store consul configurations
   * IAM role - This will be use by Consul instances to access S3 bucket
   * AWS Key pair - SSH key to access Consul instances
   * Security Group - Firewall rules used by Consul instances
   * AMI - AWS AMI pre-installed Consul (This will be use by Autoscaling Groups to autoscale)
   * Leader instance - This is the initial leader instance (This will create encrypt keys and other configurations required to autoscale instances)
   * Launch Configurations - Launch configurations used by Auto Scaling Group
   * Auto Scaling Groups - Auto Scaling Groups for Consul Servers & Clients
4. Once all the infrastructure provision, You can access Consul UI from the url shown on the console (18.193.89.205 is the IP of Leader instance)
    ```
    ======================================================================
    Consul Cluster is created with version x.xx.x
    Consul UI : http://x.xx.xx.x:8500/ui
    ======================================================================
    ```
   
## Assumptions

1. Terraform and Ansible is already installed on platform you are running the shell script to setup cluster
2. Consul Cluster ans Application will run on EC2 instances

## Improvements

1. Define error codes for better understanding failures
2. Current Consul leader instance is running outside auto-scaling. It should be started inside Auto scaling group and should configure to attach ENI with static private IP
3. Create Launch Template versions based on the consul-version
4. Configure rolling update on Autoscaling groups
5. Attach Load balancer to Consul servers (So UI can load with a DNS and can implement SSL)
6. Create CI/CD for the setup and maintenance
7. We can use Kubernetes to start consul cluster on EKS
   * servers as statefulset (Static DNS)
   * clients as daemonset (Launch on each node)
   * Create helm templates (Maintenance is easy)