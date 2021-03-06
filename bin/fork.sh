#!/bin/bash

NETWORK=$1

if [ "$NETWORK" == "local" ]; then
	# ETH_RPC_URL="http://127.0.0.1:8545"
	anvil --mnemonic "$MNEMONIC_PATH_1"

else

	ETH_RPC_URL="https://$NETWORK.infura.io/v3/$INFURA_KEY"
fi

anvil --mnemonic "$MNEMONIC_PATH_1" --rpc-url "$ETH_RPC_URL" --gas-limit 30000000
