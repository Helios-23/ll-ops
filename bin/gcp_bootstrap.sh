#!/bin/bash

# ==============================================================================
# CONFIGURATION VARIABLES (EDIT THESE)
# ==============================================================================
PROJECT_ID=""       # Your GCP Project ID
OWNER_EMAIL=""       # Your Owner/Admin email address
SA_NAME=""                 # Name of the Service Account to create
KEY_DIR="keys/tf"                # Relative directory for the key
ORG_CONSTRAINT="iam.managed.disableServiceAccountKeyCreation" # The V2 constraint
# ==============================================================================

set -e # Exit on any error

echo "🚀 Starting FULL Bootstrap for Project: $PROJECT_ID"
echo "   Owner: $OWNER_EMAIL"
echo "   Target SA: $SA_NAME"

# ------------------------------------------------------------------------------
# STEP 1: Authenticate as Owner
# ------------------------------------------------------------------------------
echo ""
echo "🔐 Step 1: Authenticating as Owner ($OWNER_EMAIL)..."
gcloud config set account $OWNER_EMAIL
gcloud auth application-default login --account $OWNER_EMAIL --quiet
gcloud config set project $PROJECT_ID

# ------------------------------------------------------------------------------
# STEP 2: Enable Foundational APIs (Must be done by Owner first)
# ------------------------------------------------------------------------------
echo ""
echo "⚙️  Step 2: Enabling foundational APIs (cloudresourcemanager, serviceusage, compute)..."
# These APIs are required to even check permissions or enable other APIs
gcloud services enable cloudresourcemanager.googleapis.com serviceusage.googleapis.com compute.googleapis.com --project $PROJECT_ID --quiet

# ------------------------------------------------------------------------------
# STEP 3: Disable Organization Policy for Key Creation (V2 Syntax)
# ------------------------------------------------------------------------------
echo ""
echo "🔓 Step 3: Disabling Org Policy constraint ($ORG_CONSTRAINT)..."
cat > policy_override.yaml << EOF
name: projects/$PROJECT_ID/policies/$ORG_CONSTRAINT
spec:
  rules:
  - enforce: false
EOF

gcloud org-policies set-policy policy_override.yaml --project $PROJECT_ID --quiet
rm -f policy_override.yaml
echo "   ⏳ Waiting 60 seconds for policy propagation..."
sleep 60

# ------------------------------------------------------------------------------
# STEP 4: Create Service Account
# ------------------------------------------------------------------------------
echo ""
echo "🤖 Step 4: Creating Service Account: $SA_NAME..."
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

if gcloud iam service-accounts describe $SA_EMAIL --project $PROJECT_ID > /dev/null 2>&1; then
  echo "   ℹ️  Service Account already exists."
else
  gcloud iam service-accounts create $SA_NAME \
    --display-name "DevOps Terraform Account" \
    --project $PROJECT_ID
  echo "   ⏳ Waiting for SA propagation..."
  sleep 5
fi

# ------------------------------------------------------------------------------
# STEP 5: Assign All Required Roles
# ------------------------------------------------------------------------------
echo ""
echo "🛡️  Step 5: Assigning Roles to $SA_EMAIL..."
ROLES=(
  "roles/compute.admin"                # Manage VMs, Disks, Images
  "roles/compute.networkAdmin"         # Manage VPC, Firewalls, Subnets
  "roles/iam.serviceAccountUser"       # Attach SA to VMs
  "roles/serviceusage.serviceUsageAdmin" # CRITICAL: Enable APIs (e.g., compute.googleapis.com)
  "roles/resourcemanager.projectIamAdmin" # CRITICAL: Manage IAM policies if needed
)

for ROLE in "${ROLES[@]}"; do
  echo "   - Adding $ROLE"
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$ROLE" \
    --quiet || echo "   ⚠️  Warning: Could not add $ROLE (may already exist)."
done

# ------------------------------------------------------------------------------
# STEP 6: Generate Key in Specific Directory
# ------------------------------------------------------------------------------
echo ""
echo "📂 Step 6: Preparing directory $KEY_DIR..."
mkdir -p "$KEY_DIR"

KEY_FILE="$KEY_DIR/terraform-key.json"
echo "📄 Generating JSON Key: $KEY_FILE..."
rm -f "$KEY_FILE"

if gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account $SA_EMAIL \
  --project $PROJECT_ID 2> key_error.tmp; then

  chmod 600 "$KEY_FILE"
  echo "✅ SUCCESS! Key generated at: $(pwd)/$KEY_FILE"
  rm -f key_error.tmp

  echo ""
  echo "=============================================================================="
  echo "🎉 BOOTSTRAP COMPLETE"
  echo "=============================================================================="
  echo "1. Export your credentials:"
  echo "   export GOOGLE_APPLICATION_CREDENTIALS=\"$(pwd)/$KEY_FILE\""
  echo ""
  echo "2. Initialize Terraform:"
  echo "   export TF_VAR_project_id=\"$PROJECT_ID\""
  echo "   export TF_VAR_region=\"us-west1\""
  echo "   terraform init"
  echo ""
  echo "3. Apply Infrastructure:"
  echo "   terraform apply"
  echo "=============================================================================="

else
  echo "❌ FAILED to generate key."
  if grep -q "disableServiceAccountKeyCreation" key_error.tmp; then
    echo "   Reason: Organization Policy still blocking key creation."
    echo "   Fix: Wait longer for Step 3 to propagate or check Org Admin permissions."
  else
    echo "   Reason:"
    cat key_error.tmp
  fi
  rm -f key_error.tmp
  exit 1
fi
