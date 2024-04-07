//SPDX-License-Identifier: MIT

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

pragma solidity 0.8.24;

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEhoughEthFee();
    error Raffle__NotEnoughTimePass();
    error Raffle__TransferError();
    error Raffle__RaffleNotOpen();
    error Raffle__NotNeededUpkeep(
        uint256 timestamp,
        RaffleState raffleState,
        uint256 currentBalance,
        uint256 numberOfPlayers
    );

    /** TYPE DECLARATION */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /** STATE VARIABLES */

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_baseline;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** EVENTS */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner, uint256 winAmount);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 baseline,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) payable VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_baseline = baseline;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimestamp = block.timestamp;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) revert Raffle__NotEhoughEthFee();
        if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * Chainkink Automation node check this function to verify that pickWinner function must be called
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    ) public view returns (bool needUpkeep, bytes memory /* performData */) {
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool isTimePass = (block.timestamp - s_lastTimestamp) >= i_interval;
        bool isPositiveBalance = address(this).balance > 0;
        bool isHavePlayers = s_players.length > 0;
        needUpkeep = (isOpen &&
            isTimePass &&
            isPositiveBalance &&
            isHavePlayers);
        return (needUpkeep, "");
    }

    function performUpkeep(bytes calldata /* performData */) public {
        (bool needUpkeep, ) = this.checkUpkeep(abi.encodePacked());
        if (!needUpkeep)
            revert Raffle__NotNeededUpkeep(
                block.timestamp,
                s_raffleState,
                address(this).balance,
                s_players.length
            );

        s_raffleState = RaffleState.CALCULATING;

        // make a request to vrfCoordinator contract to get the random number
        i_vrfCoordinator.requestRandomWords(
            i_baseline,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    // function that called by rawFulfillRandomWords() from VRFConsumerBaseV2 contract which called by vrfCoordinator to set random numbers
    // random Words must used in this function, not saved in storage variable
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        uint256 winAmount = address(this).balance;

        emit PickedWinner(winner, winAmount);

        (bool success, ) = winner.call{value: winAmount}("");
        if (!success) revert Raffle__TransferError();
    }

    /**Getter functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
