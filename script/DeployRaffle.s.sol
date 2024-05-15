//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig hc = new HelperConfig();
        // deconsructed of struct
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 baseline,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address linkToken
        ) = hc.activeNetworkConfig();

        uint256 deployerKey = hc.deployerKey();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator,
                deployerKey
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                linkToken
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            baseline,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            vrfCoordinator,
            subscriptionId,
            address(raffle),
            deployerKey
        );

        return (raffle, hc);
    }
}
