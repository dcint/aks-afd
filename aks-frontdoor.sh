#!/usr/bin/bash
##
## Create Resource group 
AZ_REGION=eastus
RESOURCE_GROUP=AKS_FrontDoor
APP_GATEWAY=AppGateway
AKS_BLUE_NODE_RG=MC_AKS_Blue_aks-blue_eastus
AKS_GREEN_NODE_RG=MC_AKS_Green_aks-blue_westus

az group create -n $RESOURCE_GROUP -l $AZ_REGION

APPGW_PIP_BLUE_ID=$(az network application-gateway show -n $APP_GATEWAY -g $AKS_BLUE_NODE_RG --query frontendIpConfigurations[0].publicIpAddress.id -o tsv)
APPGW_PIP_GREEN_ID=$(az network application-gateway show -n $APP_GATEWAY -g $AKS_GREEN_NODE_RG --query frontendIpConfigurations[0].publicIpAddress.id -o tsv)
APPGW_BLUE_PIP=$(az network public-ip show --ids $APPGW_PIP_BLUE_ID --query ipAddress -o tsv)
APPGW_GREEN_PIP=$(az network public-ip show --ids $APPGW_PIP_GREEN_ID --query ipAddress -o tsv)

az network front-door create \
--resource-group $RESOURCE_GROUP \
--name aks-frontend \
--accepted-protocols Http \
--backend-address $APPGW_BLUE_PIP \
--backend-host-header $APPGW_BLUE_PIP \
--forwarding-protocol HttpOnly

az network front-door backend-pool backend add \
--resource-group $RESOURCE_GROUP \
--front-door-name aks-frontend \
--pool-name DefaultBackendPool \
--address $APPGW_GREEN_PIP \
--backend-host-header $APPGW_GREEN_PIP