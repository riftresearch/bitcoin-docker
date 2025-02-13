#!/usr/bin/env bash

# Console colors for better legibility
COFF="\033[0m"
CINFO="\033[01;34m"
CSUCCESS="\033[0;32m"
CWARN="\033[0;33m"
CLINK="\033[0;35m"
CERROR="\033[0;31m"

# Current version of the script
CURRENT_VERSION="v.1.4.0"

# Initial launch identifier
INIT_LAUNCH="False"
INIT_LAUNCH_FILE="./volumes/.init"

# Set bitcoin network used. Default is mainnet
STACK_CRYPTO_NETWORK="mainnet"

# Toggle optional script features
STACK_CHECK_UPDATES="False"
STACK_SET_PERMISSIONS="False"
STACK_RUN_MEMPOOL_SPACE="False"

# Allocated container IP
STACK_NETWORK_SUBNET="10.21.0.0/16"
STACK_BITCOIND_IP="10.21.22.3"
STACK_ELECTRS_IP="10.21.22.5"
STACK_ELECTRS_GUI_IP="10.21.22.6"
STACK_MEMPOOL_IP="10.21.22.7"
STACK_MEMPOOL_API_IP="10.21.22.20"
STACK_MEMPOOL_DB_IP="10.21.22.21"

# Allocated container port
STACK_BITCOIND_RPC_PORT="8332"
STACK_BITCOIND_P2P_PORT="8333"
STACK_BITCOIND_PUB_RAW_BLOCK_PORT="28332"
STACK_BITCOIND_PUB_RAW_TX_PORT="28333"
STACK_ELECTRS_PORT="50001"
STACK_ELECTRS_GUI_PORT="3006"
STACK_MEMPOOL_PORT="3007"
STACK_MEMPOOL_API_PORT="3010"

# Allocated user info
STACK_UID=$(id -u)
STACK_GID=$(id -g)
STACK_BITCOIND_USER_INFO="${STACK_UID}:${STACK_GID}"
STACK_ELECTRS_USER_INFO="${STACK_UID}:${STACK_GID}"
STACK_MEMPOOL_USER_INFO="${STACK_UID}:${STACK_GID}"

# Allocated sensitive container variables
STACK_BITCOIND_USERNAME="yourusername"
STACK_BITCOIND_PASSWORD="yourpassword" # Leave blank to generate random password
STACK_MEMPOOL_DB_USERNAME="mempool"
STACK_MEMPOOL_DB_PASSWORD="mempoolpasswordd"
STACK_MEMPOOL_DB_ROOT_PASSWORD="mempoolrootpasswordd"

# Script error handling
handle_exit_code() {
    ERROR_CODE="$?"
    if [[ ${ERROR_CODE} != "0" ]]; then
        echo -e " > ${CERROR}An error occurred somewhere. Exiting with code ${ERROR_CODE}.${COFF}"        
        exit ${ERROR_CODE}
    else
        echo -e " > ${CSUCCESS}Script execution completed!${COFF}"
        exit ${ERROR_CODE}
    fi
}

trap "handle_exit_code" EXIT

# Checks if docker is running
if ( ! docker stats --no-stream > /dev/null); then
    echo -e " > ${CERROR}Docker is not running. Please double check and try again.${COFF}"
    exit 1
fi

# Checks if python 3 is running
if ( ! python3 --version > /dev/null); then
    echo -e " > ${CERROR}Python 3 is not running. Please double check and try again.${COFF}"
    exit 1
fi

# Exporting device hostname to the compose files
export DEVICE_DOMAIN_NAME=$HOSTNAME

# Variables exported to the docker compose files
export COMPOSE_IGNORE_ORPHANS="True"
export APP_CRYPTO_NETWORK="${STACK_CRYPTO_NETWORK}"
export APP_NETWORK_SUBNET="${STACK_NETWORK_SUBNET}"
export APP_BITCOIND_IP="${STACK_BITCOIND_IP}"
export APP_ELECTRS_IP="${STACK_ELECTRS_IP}"
export APP_ELECTRS_GUI_IP="${STACK_ELECTRS_GUI_IP}"
export APP_MEMPOOL_IP="${STACK_MEMPOOL_IP}"
export APP_BITCOIND_RPC_PORT="${STACK_BITCOIND_RPC_PORT}"
export APP_BITCOIND_P2P_PORT="${STACK_BITCOIND_P2P_PORT}"
export APP_BITCOIND_PUB_RAW_BLOCK_PORT="${STACK_BITCOIND_PUB_RAW_BLOCK_PORT}"
export APP_BITCOIND_PUB_RAW_TX_PORT="${STACK_BITCOIND_PUB_RAW_TX_PORT}"
export APP_BITCOIN_GUI_PORT="${STACK_BITCOIN_GUI_PORT}"
export APP_ELECTRS_PORT="${STACK_ELECTRS_PORT}"
export APP_ELECTRS_GUI_PORT="${STACK_ELECTRS_GUI_PORT}"
export APP_MEMPOOL_PORT="${STACK_MEMPOOL_PORT}"
export APP_BITCOIND_USER_INFO="${STACK_BITCOIND_USER_INFO}"
export APP_ELECTRS_USER_INFO="${STACK_ELECTRS_USER_INFO}"
export APP_MEMPOOL_USER_INFO="${STACK_MEMPOOL_USER_INFO}"
export APP_MEMPOOL_API_IP="${STACK_MEMPOOL_API_IP}"
export APP_MEMPOOL_API_PORT="${STACK_MEMPOOL_API_PORT}"
export APP_MEMPOOL_DB_IP="${STACK_MEMPOOL_DB_IP}"
export APP_MEMPOOL_DB_USERNAME="${STACK_MEMPOOL_DB_USERNAME}"
export APP_MEMPOOL_DB_PASSWORD="${STACK_MEMPOOL_DB_PASSWORD}"
export APP_MEMPOOL_DB_ROOT_PASSWORD="${STACK_MEMPOOL_DB_ROOT_PASSWORD}"

#!/bin/bash

# Generate and hash bitcoin node password / auth details
echo -e " > ${CINFO}Generating bitcoin node details...${COFF}"
BITCOIN_RPC_USERNAME="${STACK_BITCOIND_USERNAME}"
BITCOIN_RPC_PASSWORD="${STACK_BITCOIND_PASSWORD}"

# Export bitcoin node username and password to compose files
export APP_BITCOIN_RPC_USERNAME="${BITCOIN_RPC_USERNAME}"
export APP_BITCOIN_RPC_PASSWORD="${BITCOIN_RPC_PASSWORD}"

# Generating command arguments for bitcoind container
BIN_ARGS_BITCOIND=()
BIN_ARGS_BITCOIND+=( "-port=${STACK_BITCOIND_P2P_PORT}" )
BIN_ARGS_BITCOIND+=( "-rpcport=${STACK_BITCOIND_RPC_PORT}" )
BIN_ARGS_BITCOIND+=( "-rpcbind=${STACK_BITCOIND_IP}" )   # Use only one correct IP
BIN_ARGS_BITCOIND+=( "-rpcallowip=0.0.0.0/0" ) # Allow only the correct subnet
BIN_ARGS_BITCOIND+=( "-rpcuser=${APP_BITCOIN_RPC_USERNAME}" )
BIN_ARGS_BITCOIND+=( "-rpcpassword=${APP_BITCOIN_RPC_PASSWORD}" )
BIN_ARGS_BITCOIND+=( "-server=1" )
BIN_ARGS_BITCOIND+=( "-zmqpubrawblock=tcp://0.0.0.0:${STACK_BITCOIND_PUB_RAW_BLOCK_PORT}" )
BIN_ARGS_BITCOIND+=( "-zmqpubrawtx=tcp://0.0.0.0:${STACK_BITCOIND_PUB_RAW_TX_PORT}" )
BIN_ARGS_BITCOIND+=( "-deprecatedrpc=create_bd" )
BIN_ARGS_BITCOIND+=( "-deprecatedrpc=warnings" )
BIN_ARGS_BITCOIND+=( "-maxconnections=500" ) # tuned for machine
BIN_ARGS_BITCOIND+=( "-dbcache=16384" ) # tuned fo 16 gb of RAM 
BIN_ARGS_BITCOIND+=( "-assumevalid=000000000000000000001aa88fee6115a65ee5745db6787a840e1189ac46b04d" ) # block 850400
BIN_ARGS_BITCOIND+=( "-txindex=1" )




# Export the generated command to the compose file
export APP_BITCOIN_COMMAND="${BIN_ARGS_BITCOIND[*]}"

# Update the electrs.toml file with auth details
echo -e " > ${CINFO}Updating the electrs.toml file with auth details...${COFF}"
echo "auth=\"${BITCOIN_RPC_USERNAME}:${BITCOIN_RPC_PASSWORD}\"" | tee ./volumes/electrs/electrs.toml > /dev/null
echo -e " > ${CSUCCESS}The electrs.toml file has been updated!${COFF}"

# Create Docker network if it does not exist
echo -e " > ${CINFO}Checking Docker network...${COFF}"
if ! docker network inspect crypto_default >/dev/null 2>&1; then
    echo -e " > ${CINFO}Creating new Docker network...${COFF}"
    docker network create \
        --subnet=${STACK_NETWORK_SUBNET} \
        --label com.docker.compose.network=default \
        --label com.docker.compose.project=crypto \
        crypto_default
    echo -e " > ${CSUCCESS}Docker network created!${COFF}"
else
    echo -e " > ${CSUCCESS}Docker network already exists! Skipping recreation.${COFF}"
fi

# Run the containers
echo -e " > ${CINFO}Running bitcoind container...${COFF}"
docker compose -p crypto -f ./compose/docker-bitcoin.yml up -d bitcoind


# Comment out this entire block properly using standard bash comments
# echo -e " > ${CINFO}Waiting for bitcoind to be ready...${COFF}"
# sleep 10
# 
# echo -e " > ${CINFO}Running electrs, electrs_gui and explorer containers...${COFF}"
# if [[ ${STACK_RUN_MEMPOOL_SPACE} == "False" ]]; then
#     docker-compose --log-level ERROR -p crypto --file ./compose/docker-electrs.yml up -d --force-recreate electrs electrs_gui btc_explorer
# else
#     docker-compose --log-level ERROR -p crypto --file ./compose/docker-electrs.yml up -d --force-recreate electrs electrs_gui mempool_space_web mempool_space_api mempool_space_db
# fi
# 
# Check container status and display URLs
# if ( ! docker logs electrs_gui > /dev/null); then
#     echo -e " > ${CERROR}Electrum Server UI is not running due to an error.${COFF}"
#     exit 1
# else
#     echo -e " > ${CINFO}Electrum Server UI is running on${COFF}${CLINK} http://${DEVICE_DOMAIN_NAME}:${STACK_ELECTRS_GUI_PORT} ${COFF}"
# fi
# 
# if [[ ${STACK_RUN_MEMPOOL_SPACE} == "False" ]]; then
#     if ( ! docker logs btc_explorer > /dev/null); then
#         echo -e " > ${CERROR}BTC RPC Explorer is not running due to an error.${COFF}"
#         exit 1
#     else
#         echo -e " > ${CINFO}BTC RPC Explorer is running on${COFF}${CLINK} http://${DEVICE_DOMAIN_NAME}:${STACK_MEMPOOL_PORT} ${COFF}"
#     fi
# else 
#     if ( ! docker logs mempool_space_web > /dev/null); then
#         echo -e " > ${CERROR}Mempool Space Explorer is not running due to an error.${COFF}"
#         exit 1
#     else
#         echo -e " > ${CINFO}Mempool Space Explorer is running on${COFF}${CLINK} http://${DEVICE_DOMAIN_NAME}:${STACK_MEMPOOL_PORT} ${COFF}"
#     fi
# fi
