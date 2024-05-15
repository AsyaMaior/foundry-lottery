//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig, LinkToken} from "./HelperConfig.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig hc = new HelperConfig();
        (, , address vrfCoordinator, , , , ) = hc.activeNetworkConfig();
        uint256 deployerKey = hc.deployerKey();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    function createSubscription(
        address _vrfCoordinator,
        uint256 _deployerKey
    ) public returns (uint64) {
        vm.startBroadcast(_deployerKey);
        uint64 sub_id = VRFCoordinatorV2Interface(_vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        return sub_id;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint256 private constant FUND_AMOUNT = 0.5 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig hc = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId, , address linkToken) = hc
            .activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subId,
        address linkToken
    ) public {
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subId,
                uint96(FUND_AMOUNT)
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address raffle) public {
        HelperConfig hc = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId, , ) = hc
            .activeNetworkConfig();
        uint256 deployerKey = hc.deployerKey();
        addConsumer(vrfCoordinator, subId, raffle, deployerKey);
    }

    function addConsumer(
        address vrfCoordinator,
        uint64 subId,
        address raffle,
        uint256 _deployerKey
    ) public {
        vm.startBroadcast(_deployerKey);
        VRFCoordinatorV2Interface(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}
