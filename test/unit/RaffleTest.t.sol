//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Vm, Test} from "forge-std/Test.sol";
import {DeployRaffle, HelperConfig, Raffle} from "../../script/DeployRaffle.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

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
    uint256 deployerKey;

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

    /////// Modifiers /////////
    modifier enterRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        _;
    }

    modifier passTime() {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    //////// Functions //////////

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

    ////// Testing CheckUpkeep function ///////
    function testCheckUpkeepIfRaffleHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool needUpkeep, ) = raffle.checkUpkeep("");

        assert(!needUpkeep);
    }

    function testCheckUpkeepIfRaffleNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool needUpkeep, ) = raffle.checkUpkeep("");

        assert(needUpkeep == false);
    }

    function testCheckUpkeepIfTimeHasNoPass() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        (bool needUpkeep, ) = raffle.checkUpkeep("");

        assertEq(needUpkeep, false);
    }

    function testCheckUpkeepIsTrueIfAllRequiresDone() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool needUpkeep, ) = raffle.checkUpkeep("");

        assertEq(needUpkeep, true);
    }

    ////// Testing PerformUpkeep Function ////////
    function testPerformUpkeepIsRunOnlyIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpkeepIsPassIfCheckUpkeepIsTrue() public {
        uint256 time = block.timestamp;
        Raffle.RaffleState raffleState = Raffle.RaffleState.OPEN;
        uint256 balance = 0;
        uint256 numPlayers = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__NotNeededUpkeep.selector,
                time,
                raffleState,
                balance,
                numPlayers
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitRequestId()
        public
        enterRaffle
        passTime
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState rState = raffle.getRaffleState();
        Raffle.RaffleState raffleState = Raffle.RaffleState.CALCULATING;

        assertEq(entries.length, 2);
        assert(requestId > 0);
        assert(rState == raffleState);
    }

    /////// fulfillRandomWords function testing ////////
    // next test is Fuzz test, it check that fulfillRandomWords revert with any requestId
    function testFulFillRndomWordsRevertIfPerformUpkeepNotCall(
        uint256 randomRequestId
    ) public enterRaffle passTime skipFork {
        vm.expectRevert("nonexistent request"); //type of error in fulfillRandomWords function

        // next line we may make only in our fake chain, in real chain only Chainlink Node may make this call
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulFillRandomWordsPickAWinnerRestartRaffleSendMoney()
        public
        enterRaffle
        passTime
        skipFork
    {
        uint256 numberOfPlayers = 6;
        for (uint256 i = 1; i < numberOfPlayers; i++) {
            address player = address(uint160(i));
            hoax(player, STARTING_BALANCE); //same that vm.prank() with money
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * numberOfPlayers;

        // need to take a requestId
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // call fulfillRandomWords simulating Chainlink Node
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        assert(raffle.getRecentWinner() != address(0));
        assert(Raffle.RaffleState.OPEN == raffle.getRaffleState());
        assert(raffle.getLengthOfPlayers() == 0);
        assert(raffle.getLastTimestamp() == block.timestamp);
        assert(
            raffle.getRecentWinner().balance ==
                STARTING_BALANCE - entranceFee + prize
        );
    }
}
