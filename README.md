# AWS Multi-Tier Infrastructure with Terraform

This Terraform configuration deploys a highly available, multi-tier web infrastructure on AWS with load balancing, auto-scaling ready architecture, and comprehensive monitoring.

## Architecture Overview

This infrastructure creates a production-ready web application environment with the following components:

### Network Infrastructure
- **Custom VPC** (`10.0.0.0/16`) with DNS support enabled
- **3 Public Subnets** distributed across different Availability Zones for high availability
- **Internet Gateway** for public internet access
- **Route Tables** with proper routing configuration
- **VPC Flow Logs** integrated with CloudWatch for network monitoring

### Compute Resources
- **3 EC2 instances** (`t2.micro`) distributed across multiple AZs
- **Elastic IP addresses** attached to each instance for static public IP access
- **Apache HTTP Server** automatically installed via user data script
- **SSH access** configured with key-based authentication

### Load Balancing & DNS
- **Application Load Balancer** for distributing traffic across instances
- **Target Groups** with health checks for instance monitoring
- **Route53 hosted zone** (`dev.ec2deployer.com`) with DNS alias to ALB
- **HTTP to HTTPS redirect** configuration (listener on port 80 redirects to 443)

### Security
- **Security Groups** with dynamic ingress rules for HTTP (80), HTTPS (443), and SSH (22)
- **IAM integration** for CloudWatch logging permissions
- **VPC Flow Logs** for network security monitoring

## File Structure

```
├── alb.tf              # Application Load Balancer configuration
├── data.tf             # Data sources (AZs, IAM roles)
├── ec2.tf              # EC2 instances and Elastic IPs
├── output.tf           # Output values for IPs, DNS, and resource IDs
├── provider.tf         # AWS provider configuration
├── route53.tf          # DNS configuration
├── security_group.tf   # Security group rules
├── variable.tf         # Input variables and defaults
├── vpc_subnet.tf       # VPC, subnets, and networking
├── userdata.sh         # EC2 initialization script
└── key/
    └── cloud_gaming.pem # SSH private key (not tracked in git)
```

## Prerequisites

1. **Terraform** (configured for AWS Provider v3.61.0)
2. **AWS CLI** configured with appropriate credentials
3. **AWS Account** with necessary permissions for:
   - VPC and subnet creation
   - EC2 instance management
   - Load balancer configuration
   - Route53 DNS management
   - CloudWatch and IAM access

## Dependencies

### External Dependencies
- **Pre-existing IAM Role**: `cloudwatch-logger` - Must exist in your AWS account for VPC Flow Logs
- **Key Pair**: `cloud_gaming` - SSH key pair must be created in AWS EC2 console
- **Route53 Domain**: The configuration assumes you own or can create the domain `dev.ec2deployer.com`

### Terraform Provider Dependencies
- `hashicorp/aws` version 3.61.0
- `hashicorp/null` version 3.2.1 (for provisioners)

## Deployment Instructions

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd Terraform-task-2
   ```

2. **Configure AWS credentials**:
   ```bash
   aws configure
   # OR set environment variables:
   # export AWS_ACCESS_KEY_ID="your-access-key"
   # export AWS_SECRET_ACCESS_KEY="your-secret-key"
   ```

3. **Create required AWS resources manually**:
   - Create IAM role named `cloudwatch-logger` with CloudWatch Logs permissions
   - Create EC2 Key Pair named `cloud_gaming` and save the private key to `key/cloud_gaming.pem`

4. **Initialize and deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Access your application**:
   - Use the ALB DNS name from the output
   - Or access via Route53 domain: `http://dev.ec2deployer.com`

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `custom_vpc` | CIDR block for VPC | `10.0.0.0/16` | No |
| `instance_tenancy` | VPC tenancy type | `default` | No |
| `ami_id` | AMI ID for EC2 instances | `ami-087c17d1fe0178315` | No |
| `instance_type` | EC2 instance type | `t2.micro` | No |
| `ssh_private_key` | Path to SSH private key | `./key/cloud_gaming.pem` | No |

## Outputs

The configuration provides the following outputs:
- `private_ip` - Private IP addresses of all instances
- `public_ip` - Public IP addresses (Elastic IPs) of all instances
- `public_dns` - Public DNS names of all instances
- `private_dns` - Private DNS names of all instances
- `alb_id` - Application Load Balancer DNS name
- `vpc_id` - VPC ID for reference

## Security Considerations ⚠️

### **SECURITY WARNINGS - ACTION REQUIRED**

1. **SSH Access Configuration**:
   - Security group allows SSH access from `0.0.0.0/0` (entire internet)
   - **Recommendation**: Restrict SSH access to specific IP ranges or use bastion host
   - **Fix**: Update `security_group.tf` to limit SSH access:
     ```hcl
     cidr_blocks = ["YOUR_IP_ADDRESS/32"]  # Replace with your IP
     ```

2. **EC2 Instance Security**:
   - User data script enables SSH password authentication
   - **Risk**: This weakens SSH security by allowing password-based attacks
   - **Recommendation**: Remove password authentication and rely solely on key-based auth

3. **AWS Credentials**:
   - Provider configuration contains placeholder for hardcoded credentials
   - **Critical**: Never commit AWS credentials to version control
   - **Best Practice**: Use AWS CLI profiles, IAM roles, or environment variables

4. **Instance Metadata Security**:
   - EC2 instances use default metadata configuration
   - **Recommendation**: Enable IMDSv2 for enhanced security:
     ```hcl
     metadata_options {
       http_tokens = "required"
       http_put_response_hop_limit = 1
     }
     ```

5. **Network Security**:
   - All instances are in public subnets
   - **Recommendation**: Consider private subnets for application servers with NAT Gateway

## Monitoring and Logging

- **VPC Flow Logs**: Enabled for all network traffic analysis
- **CloudWatch Log Group**: `VPC-FlowLogs-Group-3` with 30-day retention
- **Target Group Health Checks**: Automatic monitoring of instance health

## Cost Optimization

Current resources and estimated monthly costs:
- 3 x t2.micro instances: ~$15-20/month
- Application Load Balancer: ~$22/month
- 3 x Elastic IPs: ~$3.60/month
- VPC resources: Minimal cost
- **Total estimated**: ~$40-50/month

## Scaling and High Availability

The architecture is designed for:
- **Multi-AZ deployment** across 3 availability zones
- **Load balancer** for traffic distribution
- **Auto-scaling ready** (target groups configured)
- **Health checks** for automatic failure detection

## Troubleshooting

### Common Issues:
1. **"cloudwatch-logger" IAM role not found**: Create the IAM role manually
2. **Key pair not found**: Ensure `cloud_gaming` key pair exists in AWS
3. **Route53 domain issues**: Verify domain ownership and hosted zone configuration
4. **Instance launch failures**: Check subnet capacity and instance limits

### Useful Commands:
```bash
# Check resource status
terraform show

# View specific resource details
terraform state show aws_instance.instance[0]

# Force resource recreation
terraform taint aws_instance.instance[0]
```

## Contributing

When making changes:
1. Test in a development environment first
2. Update this README if architecture changes
3. Follow security best practices
4. Validate configurations before applying

## Version History

- **v1.0**: Initial infrastructure setup with 3-tier architecture
- **Current**: AWS Provider 3.61.0, Terraform-compatible