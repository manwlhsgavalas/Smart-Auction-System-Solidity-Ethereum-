// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract auction {

    // --- State Variables ---
    address payable public beneficiary;
    uint256 public auctionEndTime;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) pendingReturns;
    bool ended;

    // --- Events ---
    event HighestBidIncreased(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    // --- Constructor ---
    constructor(uint256 biddingTime, address payable beneficiaryAddress) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    // --- Functions ---

    /**
     * @notice Place a bid. The Ether sent is your bid.
     */
    function bid() public payable {
        require(block.timestamp <= auctionEndTime, "Auction already ended.");
        require(msg.value > highestBid, "There already is a higher or equal bid.");

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw a bid that was outbid.
     * @return success True if the withdrawal was successful.
     */
    function withdraw() public returns (bool success) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /**
     * @notice End the auction and send the highest bid to the beneficiary.
     * Can be called by anyone once the auction time has passed.
     */
    function auctionEnd() public {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }
}
