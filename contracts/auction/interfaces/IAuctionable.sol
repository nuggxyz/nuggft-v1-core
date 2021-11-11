// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '../../interfaces/IExchangeable.sol';
import '../../interfaces/IWETH9.sol';

/**
 * @title IAuctionable
 * @dev interface for Auctionable.sol
 */
interface IAuctionable is IExchangeable {
    struct Bid {
        bytes32 id;
        uint256 auctionId;
        address account;
        uint256 amount;
        bool claimed;
        Currency currency;
        uint256 bidnum;
        bool first;
    }

    struct Auction {
        uint256 auctionId;
        bool init;
        Bid top;
        Bid last;
        // uint256 bidCount;
        // bytes data;
        // Bid top;
        // Bid lastId;
    }

    event WinningClaim(uint256 indexed epoch, address indexed user, uint256 amount);

    event NormalClaim(uint256 indexed epoch, address indexed user, uint256 amount, Currency currency);

    event BidPlaced(uint256 indexed epoch, address indexed user, uint256 amount, Currency currency);

    event AuctionInit(uint256 indexed epoch, uint256 amount);

    function getAuction(uint256 id) external view returns (Auction memory res);

    // function getBidByHash(bytes32 bidhash) external view returns (Bid memory res);

    function getBid(uint256 auctionId, address account) external view returns (Bid memory bid);

    /**
     * @dev #TODO
     */
    function placeBid(
        uint256 epoch,
        uint256 amount,
        Currency currency
    ) external payable;

    /**
     * @dev #TODO
     */
    function claim(uint256 epoch, Currency currency) external;
}
