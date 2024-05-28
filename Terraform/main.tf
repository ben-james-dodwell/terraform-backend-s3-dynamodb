resource "aws_kms_key" "terraform_backend" {
  description             = "terraform_backend"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Id": "default",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${var.aws_account}:root"
        },
        "Action": "kms:*",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${var.aws_account}:user/terraform"
        },
        "Action": "kms:*",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${var.aws_account}:role/GitHubActionsTerraformRole" 
        },
        "Action": "kms:*",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "logs.${var.region}.amazonaws.com" 
        },
        "Action": [
            "kms:Encrypt*",
            "kms:Decrypt*",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:Describe*"
        ],
        "Resource": "*"
      }     
    ]
  }
POLICY
}

resource "aws_s3_bucket" "terraform_bucket" {
  #checkov:skip=CKV_AWS_144:Cross-region replication not required for Terraform state bucket.
  #checkov:skip=CKV_AWS_18:Access logging not required for Terraform state bucket.
  #checkov:skip=CKV2_AWS_62:Event notifications not required for Terraform state bucket.
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration not required for Terraform state bucket.
  bucket = var.backend_bucket
}

resource "aws_s3_bucket_public_access_block" "terraform_bucket" {
  bucket                  = aws_s3_bucket.terraform_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_versioning" {
  bucket = aws_s3_bucket.terraform_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "terraform_object_lock" {
  bucket = aws_s3_bucket.terraform_bucket.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 5
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.terraform_versioning
  ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_encryption" {
  bucket = aws_s3_bucket.terraform_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_backend.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_dynamodb_table" "terraform_table" {
  name         = var.backend_dynamo_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_backend.arn
  }
}
