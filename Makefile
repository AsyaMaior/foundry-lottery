-include .env

.PHONY: all test deploy

install: 
	forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
	forge install transmissions11/solmate --no-commit
	forge install Cyfrin/foundry-devops@0.0.11 --no-commit

test:
	forge test

fork-test:
	@forge test --fork-url $(RPC_URL_ETHEREUM_SEPOLIA)

NETWORK_ARGS := --rpc-url $(RPC_URL_ANVIL) --private-key $(PRIVATE_KEY_ANVIL) --broadcast -vvvv

ifeq ($(findstring --network sepolia, $(ARGS)), --network sepolia)
	NETWORK_ARGS := --rpc-url $(RPC_URL_ETHEREUM_SEPOLIA) --private-key $(PRIVATE_KEY) --broadcast --etherscan-api-key $(ETHERSCAN_API_KEY) --verify -vvvv
endif


deploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)