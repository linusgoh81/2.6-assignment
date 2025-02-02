# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Or your preferred version
    }
  }
}

provider "aws" {
  region = "ap-southeast-1" # Replace with your AWS region
}

# DynamoDB Table (Assuming it already exists - if not, define it here)
data "aws_dynamodb_table" "book_inventory" {
  name = "linus-bookinventory"  # Replace with your table name
}

# IAM Policy for DynamoDB Read Access
resource "aws_iam_policy" "dynamodb_read_policy" {
  name = "linus-dynamodb-read-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:ListTables",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query", # Add if needed
        ],
        Resource = data.aws_dynamodb_table.book_inventory.arn
      },
    ]
  })
}

# IAM Role for EC2
resource "aws_iam_role" "dynamodb_read_role" {
  name = "linus-dynamodb-read-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "dynamodb_read_policy_attachment" {
  role       = aws_iam_role.dynamodb_read_role.name
  policy_arn = aws_iam_policy.dynamodb_read_policy.arn
}


# Example EC2 Instance (You would configure this further)
resource "aws_instance" "dynamodb_reader_ec2" {
  ami           = "ami-0c94855ba95c574c8" # Example Amazon Linux 2023 AMI - replace with appropriate AMI
  instance_type = "t2.micro" # Or your preferred instance type
  # ... other EC2 configurations ...

  iam_instance_profile = aws_iam_role.dynamodb_read_role.name # Attach the IAM role

  # User data to test access after instance launch (optional)
  user_data = <<EOF
#!/bin/bash
aws dynamodb list-tables
aws dynamodb scan --table-name ${data.aws_dynamodb_table.book_inventory.name}
EOF
}

# Output the EC2 public IP (Optional)
output "ec2_public_ip" {
  value = aws_instance.dynamodb_reader_ec2.public_ip
}