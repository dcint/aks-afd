#!/usr/bin/bash
##
## Create Resource group 
AZ_REGION=eastus
RESOURCE_GROUP=AKS_Blue
az group create -n $RESOURCE_GROUP -l $AZ_REGION

## Create Vnet and Public IP for AppGw
##AKS_Upgrade
VNET_NAME=AksVnet
APPGW_SUBNET=AppGwSubnet
AKS_SUBNET_BLUE=AksSubnetBlue
AKS_SUBNET_GREEN=AksSubnetGreen
 
az network vnet create -n $VNET_NAME -g $RESOURCE_GROUP -l $AZ_REGION --address-prefix 10.0.0.0/8
 
az network vnet subnet create \
-g $RESOURCE_GROUP \
-n $AKS_SUBNET_BLUE \
--address-prefixes 10.240.0.0/16 \
--vnet-name $VNET_NAME

az network vnet subnet create \
-g $RESOURCE_GROUP \
-n $AKS_SUBNET_GREEN \
--address-prefixes 10.241.0.0/16 \
--vnet-name $VNET_NAME

## Create Blue Cluster with AppGW 
APP_GATEWAY=AppGateway
AKS_SUBNET_ID=$(az network vnet subnet show -g $RESOURCE_GROUP --vnet-name $VNET_NAME --name $AKS_SUBNET_BLUE --query id -o tsv)
AKS_BLUE=aks-blue
az aks create -n $AKS_BLUE \
-g $RESOURCE_GROUP \
-l $AZ_REGION \
--generate-ssh-keys \
--network-plugin azure \
--enable-managed-identity \
--vnet-subnet-id $AKS_SUBNET_ID \
-a ingress-appgw \
--appgw-name $APP_GATEWAY \
--appgw-subnet-cidr 10.1.0.0/16


## Create Green Cluster 
AKS_SUBNET_GREEN_ID=$(az network vnet subnet show -g $RESOURCE_GROUP --vnet-name $VNET_NAME --name $AKS_SUBNET_GREEN --query id -o tsv)
AKS_GREEN=aks-green
az aks create -n $AKS_GREEN \
-g $RESOURCE_GROUP \
-l $AZ_REGION \
--generate-ssh-keys \
--network-plugin azure \
--enable-managed-identity \
--vnet-subnet-id $AKS_SUBNET_GREEN_ID \

## APPGW AGIC addon to Green Cluster
AKS_GREEN_NODE_RG=$(az aks show -n $AKS_BLUE  -g $RESOURCE_GROUP --query "nodeResourceGroup" -o tsv)
APPGW_ID=$(az network application-gateway show -n $APP_GATEWAY -g $AKS_GREEN_NODE_RG --query "id" -o tsv) 
az aks enable-addons -n $AKS_GREEN -g $RESOURCE_GROUP -a ingress-appgw --appgw-id $APPGW_ID