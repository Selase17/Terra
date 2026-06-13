#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# bootstrap-backend.sh
#
# Run ONCE before your first `terraform init` to create:
#   • An S3 bucket for remote Terraform state
#   • A DynamoDB table for state locking
#
# Usage:
#   chmod +x scripts/bootstrap-backend.sh
#   ./scripts/bootstrap-backend.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REGION="${AWS_REGION:-eu-central-1}"
PROJECT="${PROJECT_NAME:-3tier-app}"
ENV="${ENVIRONMENT:-production}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

BUCKET_NAME="${PROJECT}-${ENV}-tf-state-${ACCOUNT_ID}"
TABLE_NAME="${PROJECT}-${ENV}-tf-state-lock"

echo "──────────────────────────────────────────"
echo " Bootstrapping Terraform remote backend"
echo "  Region  : $REGION"
echo "  Bucket  : $BUCKET_NAME"
echo "  Table   : $TABLE_NAME"
echo "──────────────────────────────────────────"

# ─── S3 Bucket ────────────────────────────────
echo "Creating S3 bucket..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "  Bucket already exists — skipping creation"
else
  if [ "$REGION" = "eu-central-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "  ✓ Bucket created"
fi

echo "Configuring S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"},
      "BucketKeyEnabled": true
    }]
  }'

aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "  ✓ Versioning, encryption, and public access block configured"

# ─── DynamoDB Lock Table ───────────────────────
echo "Creating DynamoDB lock table..."
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
  echo "  Table already exists — skipping creation"
else
  aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION" \
    --tags Key=Project,Value="$PROJECT" Key=Environment,Value="$ENV" Key=ManagedBy,Value=bootstrap

  echo "  ✓ DynamoDB table created"
fi

# ─── Output init command ────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  Bootstrap complete! Run this to init:"
echo ""
echo "  terraform init \\"
echo "    -backend-config=\"bucket=$BUCKET_NAME\" \\"
echo "    -backend-config=\"key=${PROJECT}/terraform.tfstate\" \\"
echo "    -backend-config=\"region=$REGION\" \\"
echo "    -backend-config=\"encrypt=true\" \\"
echo "    -backend-config=\"dynamodb_table=$TABLE_NAME\""
echo ""
echo "  Add these as GitHub Secrets:"
echo "    TF_STATE_BUCKET = $BUCKET_NAME"
echo "    TF_LOCK_TABLE   = $TABLE_NAME"
echo "══════════════════════════════════════════"
