The `Raffle` smart contract is a lottery that can be participated in by calling the `enterRaffle()` function and making a contribution in the amount of `i_entranceFee`. After some `i_interval`, [ChainLink Automation](https://automation.chain.link/) will start the process of selecting a winner.
The winner will be selected using [ChainLink VRF](https://vrf.chain.link/). 

### Requirements

 - `FundMe` contract use a Foundry framework. [Install foundry](https://getfoundry.sh/)

### Work with project

1. Clone git repo and build project

```bash
    git clone https://github.com/AsyaMaior/foundry-lottery
    cd foundry-fund-me-f23
    forge build
```

2. Install the dependencies

```bash
    make install
```

3. To deploy and interact with the contract, create your `.env` file; an example is provided in the repository. Than utilize a `Makefile` .

```bash
    #to deploy on anvil
    make deploy

    #to deploy on sepolia
    make deploy ARGS="--network sepolia"
```

Deploy script automatically creates and configures a VRF subscription. Chainlink Automation subscriptions must be set up independently via the [website](https://automation.chain.link/). You must have some LINK token on the `owner` address.

4. To run tests use the following command:

```bash
    forge test
```

To run tests using a forked mainnet network, use the following command:

```bash
    make fork-test
```

### Realization on sepolia

Smart contract Raffle: https://sepolia.etherscan.io/address/0x82511ca875ecdf4c9da3da91b2b27aafa712e1ff

ChainLink VRF Subscription: https://vrf.chain.link/sepolia/11713

My subscription to ChainLink VRF: https://vrf.chain.link/sepolia/11713


---
This project was created and finalized while completing a course on [Cyfrin Updraft](https://updraft.cyfrin.io/)
