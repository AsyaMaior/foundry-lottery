//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mock/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 baseline;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address linkToken;
    }

    NetworkConfig public activeNetworkConfig;
    uint256 public deployerKey;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11155111) {
            (activeNetworkConfig, deployerKey) = getSepoliaNetworkConfig();
        } else {
            (
                activeNetworkConfig,
                deployerKey
            ) = getOrCreateAnvilNetworkConfig();
        }
    }

    function getSepoliaNetworkConfig()
        public
        view
        returns (NetworkConfig memory, uint256)
    {
        return (
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                baseline: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            }),
            vm.envUint("PRIVATE_KEY")
        );
    }

    function getOrCreateAnvilNetworkConfig()
        public
        returns (NetworkConfig memory, uint256)
    {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return (activeNetworkConfig, deployerKey);
        }

        uint96 baseFee = 0.25 ether; //LINK
        uint96 gasPriceLink = 1e9; // 1 gwei of LINK

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return (
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: address(vrfCoordinatorMock),
                baseline: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                linkToken: address(link)
            }),
            DEFAULT_ANVIL_PRIVATE_KEY
        );
    }
}
