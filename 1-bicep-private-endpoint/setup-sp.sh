#!/bin/bash
# Creates an Azure AD application and service principal with Contributor role
# on the resource group — equivalent to the azuread_* resources in the
# Terraform version, which Bicep does not natively support.
#
# Usage: bash setup-sp.sh [prefix]
#   prefix defaults to 'mi'

set -euo pipefail

PREFIX=${1:-mi}
RG_NAME="${PREFIX}-learn-net-rg"

echo "Creating Azure AD application..."
APP_ID=$(az ad app create --display-name "${PREFIX}-learn-app" --query appId -o tsv)

echo "Creating service principal..."
SP_OBJ_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)

echo "Creating client secret..."
SECRET=$(az ad app credential reset --id "$APP_ID" --query password -o tsv)

echo "Assigning Contributor role on resource group..."
RG_ID=$(az group show --name "$RG_NAME" --query id -o tsv)
az role assignment create \
  --assignee-object-id "$SP_OBJ_ID" \
  --assignee-principal-type ServicePrincipal \
  --role Contributor \
  --scope "$RG_ID"

TENANT_ID=$(az account show --query tenantId -o tsv)

echo ""
echo "Service principal created:"
echo "  ARM_CLIENT_ID=$APP_ID"
echo "  ARM_CLIENT_SECRET=$SECRET"
echo "  ARM_TENANT_ID=$TENANT_ID"
echo ""
echo "To delete later:"
echo "  az ad app delete --id $APP_ID"
