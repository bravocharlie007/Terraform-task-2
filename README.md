# ⚠️ AWS Gaming PC Infrastructure - LEGACY MONOLITHIC VERSION

> **⚠️ IMPORTANT NOTICE**: This is a **legacy monolithic version** of a multi-workspace Terraform architecture. The **recommended approach** uses separate workspaces for better modularity and security. See the [Multi-Workspace Architecture](#multi-workspace-architecture-recommended) section below.

## What This Repository Does

This Terraform configuration was originally designed as a **cloud gaming PC hosting platform** for you and your brothers. It deploys a highly available, multi-tier web infrastructure on AWS that can be adapted for gaming applications.

### ⚠️ Gaming PC Security Context

**Critical Understanding**: This infrastructure was designed for **gaming PC hosting** where:
- You need remote access for you and your brothers
- IP addresses of users may change frequently  
- Traditional security models (fixed IP whitelisting) don't work well
- High-performance instances may be needed for gaming workloads

## Architecture Overview

This infrastructure creates a production-ready environment with the following components:

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
- **SSH access** configured with password authentication for easier brother access

### Load Balancing & DNS
- **Application Load Balancer** for distributing traffic across instances
- **Target Groups** with health checks for instance monitoring
- **Route53 hosted zone** (`dev.ec2deployer.com`) with DNS alias to ALB
- **HTTP to HTTPS redirect** configuration (listener on port 80 redirects to 443)

### Security
- **Security Groups** with dynamic ingress rules for HTTP (80), HTTPS (443), and SSH (22)
- **IAM integration** for CloudWatch logging permissions
- **VPC Flow Logs** for network security monitoring

## Multi-Workspace Architecture (RECOMMENDED)

**Your current setup uses a superior 3-workspace architecture:**

### 1. VPC Workspace (`bravocharlie007/vpc`)
**Purpose**: Network foundation layer
- Creates VPC, subnets, Internet Gateway, route tables
- Uses modern Terraform with proper locals and dynamic configurations
- Outputs network IDs for consumption by other workspaces
- **Deploy First** - Foundation for all other infrastructure

### 2. Compute Workspace (`bravocharlie007/compute`) 
**Purpose**: Application and load balancing layer
- Creates ALB, EC2 instances, security groups, Elastic IPs
- Uses `terraform_remote_state` to reference VPC outputs
- More advanced security group configurations
- Better instance management with proper tagging
- **Deploy Second** - Requires VPC workspace outputs

### 3. Zone-Infrastructure Workspace (`bravocharlie007/zone-infrastructure`)
**Purpose**: DNS management layer  
- Creates Route53 zones and DNS records
- Points DNS to ALB from compute workspace
- Handles subdomain routing (dev.ec2deployer.com, beta.dev, etc.)
- **Deploy Third** - Requires compute workspace ALB outputs

### Deployment Order
```
1. VPC Workspace → 2. Compute Workspace → 3. Zone-Infrastructure Workspace
     (Network)           (Compute+ALB)            (DNS)
```

**This monolithic repository combines all three layers**, which works but is harder to maintain and less secure.

## 🎮 Gaming PC Security Recommendations

### Understanding the Challenge
For gaming PC hosting, you face unique security challenges:
- **Dynamic IPs**: Your brothers' IPs change frequently
- **Multiple Users**: Need access for multiple family members  
- **High-Performance Requirements**: Gaming may need specific ports/protocols
- **Ease of Access**: Can't be too complicated for non-technical users

### Solution 1: AWS Client VPN (Most Secure)
**Best for**: Maximum security with manageable complexity

```hcl
resource "aws_ec2_client_vpn_endpoint" "gaming_vpn" {
  description            = "Gaming PC VPN Access"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  client_cidr_block     = "10.1.0.0/16"
  vpc_id                = aws_vpc.custom_vpc.id
  
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_client.arn
  }
}

# Replace open SSH with VPN-only access
resource "aws_security_group_rule" "gaming_vpn_access" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.1.0.0/16"]  # VPN client range
  security_group_id = aws_security_group.sg.id
}
```

**Benefits**: 
- Brothers get VPN profiles to install
- No IP whitelisting needed
- Full encryption
- Can access gaming ports securely

### Solution 2: Dynamic IP Registration API (Practical)
**Best for**: Balance of security and convenience

```hcl
# Lambda function for IP management
resource "aws_lambda_function" "gaming_ip_updater" {
  filename         = "ip_updater.zip"
  function_name    = "gaming-ip-whitelist"
  role            = aws_iam_role.lambda_sg_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  
  environment {
    variables = {
      SECURITY_GROUP_ID = aws_security_group.sg.id
      WEBHOOK_SECRET    = var.webhook_secret
    }
  }
}

# API Gateway for IP registration
resource "aws_api_gateway_rest_api" "ip_registration" {
  name        = "gaming-ip-registration"
  description = "API for brothers to register their current IPs"
}

resource "aws_api_gateway_resource" "register_ip" {
  rest_api_id = aws_api_gateway_rest_api.ip_registration.id
  parent_id   = aws_api_gateway_rest_api.ip_registration.root_resource_id
  path_part   = "register-ip"
}
```

**Benefits**:
- Brothers visit simple webpage to register their current IP
- Automatically adds/removes IPs from security group
- Can include expiration times (e.g., 24 hours)
- Simple webhook integration

### Solution 3: AWS Systems Manager Session Manager (No SSH)
**Best for**: Eliminating SSH entirely

```hcl
# Add to EC2 instances
resource "aws_iam_role" "gaming_instance_role" {
  name = "gaming-instance-ssm-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gaming_ssm_policy" {
  role       = aws_iam_role.gaming_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "gaming_profile" {
  name = "gaming-instance-profile"
  role = aws_iam_role.gaming_instance_role.name
}

# Remove SSH security group rule entirely
# Access via: aws ssm start-session --target i-1234567890abcdef0
```

**Benefits**:
- No SSH ports exposed to internet
- Access through AWS CLI/Console
- Built-in logging and auditing
- Works from anywhere with AWS credentials

### Solution 4: Gaming-Optimized Instance Configuration

```hcl
# Upgrade to gaming instances
resource "aws_instance" "gaming_instance" {
  count                = 1  # Usually one powerful gaming instance
  ami                  = "ami-0c02fb55956c7d316"  # Windows Server for gaming
  instance_type        = "g4dn.xlarge"  # GPU instance for gaming
  subnet_id            = element(aws_subnet.public_subnet.*.id, count.index)
  security_groups      = [aws_security_group.gaming_sg.id]
  key_name             = "cloud_gaming"
  
  # Enable enhanced networking
  sriovenabling = true
  
  # EBS optimized for better performance
  ebs_optimized = true
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 100
    iops        = 3000
    throughput  = 250
  }
  
  user_data = file("gaming_userdata.ps1")
  
  tags = {
    "Name"        = "Gaming-PC-${count.index}"
    "Environment" = "Gaming"
    "Purpose"     = "Family-Gaming-Server"
  }
}

# Gaming-specific security group
resource "aws_security_group" "gaming_sg" {
  name        = "Gaming-PC-SG"
  description = "Security group for gaming PC"
  vpc_id      = aws_vpc.custom_vpc.id
  
  # RDP for Windows gaming instances
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with VPN/IP solution above
  }
  
  # Steam In-Home Streaming
  ingress {
    from_port   = 27036
    to_port     = 27037
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Gaming ports (customize as needed)
  ingress {
    from_port   = 7777
    to_port     = 7784
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Current Security Issues ⚠️

### **IMMEDIATE SECURITY CONCERNS**:

1. **SSH Wide Open**: Security group allows SSH from `0.0.0.0/0` (entire internet)
   - **Current Risk**: Anyone can attempt to SSH to your gaming instances
   - **Gaming Solution**: Use VPN or dynamic IP registration above

2. **Password Authentication Enabled**: 
   ```bash
   # In userdata.sh:
   sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
   ```
   - **Current Risk**: Brute force password attacks possible
   - **Gaming Solution**: Switch to key-only auth or eliminate SSH entirely

3. **Gaming Instance Exposure**: 
   - All instances in public subnets with direct internet access
   - No network segmentation for gaming vs web traffic
   - **Gaming Solution**: Use private subnets with NAT Gateway, VPN access

4. **AWS Credentials Structure**: 
   ```hcl
   provider "aws" {
     access_key = ""  # Dangerous even if empty
     secret_key = ""  # Should never be in code
   }
   ```
   - **Gaming Solution**: Use AWS CLI profiles or IAM roles

### Recommended Gaming Security Architecture:

```
Internet → VPN/API Gateway → Private Gaming Subnets → Gaming Instances
   ↓
Security Groups allow only VPN traffic
   ↓  
Systems Manager for administration (no SSH)
   ↓
CloudWatch for monitoring gaming sessions
```

## File Structure (Legacy Monolithic)

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

## Migration to Multi-Workspace Architecture

**Recommended**: Migrate from this monolithic approach to the 3-workspace architecture:

1. **Use existing VPC workspace** (`bravocharlie007/vpc`) - ✅ Already deployed
2. **Use existing Compute workspace** (`bravocharlie007/compute`) - ✅ Already deployed  
3. **Use existing Zone-Infrastructure workspace** (`bravocharlie007/zone-infrastructure`) - ✅ Already deployed
4. **Deprecate this repository** - Contains duplicated/outdated configurations

## Prerequisites (Legacy)

1. **Terraform** (configured for AWS Provider v3.61.0)
2. **AWS CLI** configured with appropriate credentials
3. **AWS Account** with necessary permissions for:
   - VPC and subnet creation
   - EC2 instance management
   - Load balancer configuration
   - Route53 DNS management
   - CloudWatch and IAM access

## Dependencies (Legacy)

### External Dependencies
- **Pre-existing IAM Role**: `cloudwatch-logger` - Must exist in your AWS account for VPC Flow Logs
- **Key Pair**: `cloud_gaming` - SSH key pair must be created in AWS EC2 console
- **Route53 Domain**: The configuration assumes you own or can create the domain `dev.ec2deployer.com`

### Terraform Provider Dependencies
- `hashicorp/aws` version 3.61.0
- `hashicorp/null` version 3.2.1 (for provisioners)

## Configuration Variables (Legacy)

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `custom_vpc` | CIDR block for VPC | `10.0.0.0/16` | No |
| `instance_tenancy` | VPC tenancy type | `default` | No |
| `ami_id` | AMI ID for EC2 instances | `ami-087c17d1fe0178315` | No |
| `instance_type` | EC2 instance type | `t2.micro` | No |
| `ssh_private_key` | Path to SSH private key | `./key/cloud_gaming.pem` | No |

## Outputs (Legacy)

The configuration provides the following outputs:
- `private_ip` - Private IP addresses of all instances
- `public_ip` - Public IP addresses (Elastic IPs) of all instances
- `public_dns` - Public DNS names of all instances
- `private_dns` - Private DNS names of all instances
- `alb_id` - Application Load Balancer DNS name
- `vpc_id` - VPC ID for reference