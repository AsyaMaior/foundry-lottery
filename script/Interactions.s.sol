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
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address _vrfCoordinator
    ) public returns (uint64) {
        return VRFCoordinatorV2Interface(_vrfCoordinator).createSubscription();
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint256 private constant FUND_AMOUNT = 0.01 ether;

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
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subId,
                uint96(FUND_AMOUNT)
            );
        } else {
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer {
    function addConsumerUsingConfig(address raffle) public {
        HelperConfig hc = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId, , ) = hc
            .activeNetworkConfig();
        addConsumer(vrfCoordinator, subId, raffle);
    }

    function addConsumer(
        address vrfCoordinator,
        uint64 subId,
        address raffle
    ) public {
        VRFCoordinatorV2Interface(vrfCoordinator).addConsumer(subId, raffle);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}
