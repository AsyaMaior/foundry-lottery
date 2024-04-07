//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle, HelperConfig, Raffle} from "../../script/DeployRaffle.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig hc;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 baseline;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, hc) = deployer.run();

        (
            entranceFee,
            interval,
            vrfCoordinator,
            baseline,
            subscriptionId,
            callbackGasLimit,
            linkToken
        ) = hc.activeNetworkConfig();

        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleStateIsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    ///// Testing Enter Raffle Function /////
    function testEnterRaffleRevertIfSendSmallMoney() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEhoughEthFee.selector);
        raffle.enterRaffle();
    }

    function testPlayerAddToSPlayersArray() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        address player = raffle.getPlayer(0);
        assertEq(player, PLAYER);
    }

    function testEmitEventInEnterRaffle() public {
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.EnteredRaffle(PLAYER);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testRevertIfRaffleCalculating() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
    }
}
