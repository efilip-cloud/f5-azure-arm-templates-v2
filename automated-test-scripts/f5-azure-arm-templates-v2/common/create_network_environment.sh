#  expectValue = "Template validation succeeded"
#  expectFailValue = "Template validation failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

TMP_DIR='/tmp/<DEWPOINT JOB ID>'

# Create vnet and subnets for test
# download and use --template-file because --template-uri is limiting
TEMPLATE_FILE=${TMP_DIR}/<RESOURCE GROUP>-net-env.json
curl -k file://$PWD/examples/modules/network/network.json -o ${TEMPLATE_FILE}

NAT_GATEWAY=False
if [[ "<PROVISION PUBLIC IP>" == "False" ]]; then
    echo "Provisioning NAT gateway"
    NAT_GATEWAY=True
fi

NUM_SUBNETS=4
if echo "<TEMPLATE URL>" | grep "autoscale"; then
    NUM_SUBNETS=2
fi

DEPLOY_PARAMS='{"vnetName":{"value":"vnet-<DEWPOINT JOB ID>"},"numSubnets":{"value":'$NUM_SUBNETS'},"vnetAddressPrefix":{"value":"10.0"},"createNatGateway":{"value":'$NAT_GATEWAY'}}'

DEPLOY_PARAMS_FILE=${TMP_DIR}/deploy_params.json

# save deployment parameters to a file, to avoid weird parameter parsing errors with certain values
# when passing as a variable. I.E. when providing an sshPublicKey
echo ${DEPLOY_PARAMS} > ${DEPLOY_PARAMS_FILE}

echo "DEBUG: DEPLOY PARAMS"
echo ${DEPLOY_PARAMS}

VALIDATE_RESPONSE=$(az deployment group validate --resource-group <RESOURCE GROUP> --template-file ${TEMPLATE_FILE} --parameters @${DEPLOY_PARAMS_FILE})
VALIDATION=$(echo ${VALIDATE_RESPONSE} | jq .properties.provisioningState)
if [[ $VALIDATION == \"Succeeded\" ]]; then
    az deployment group create --verbose --no-wait --template-file ${TEMPLATE_FILE} -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env --parameters @${DEPLOY_PARAMS_FILE}
    echo "Template validation succeeded"
else
    echo "Template validation failed: ${VALIDATE_RESPONSE}"
fi