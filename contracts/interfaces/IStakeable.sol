// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '../libraries/StakeMath.sol';

/**
 * @title IStakeable
 * @dev interface for Stakeable.sol
 */
interface IStakeable {
    event TokenEarn(address indexed account, address sender, uint256 amount);
    event SharesIncrease(address indexed account, address sender, uint256 amount);
    event SharesDecrease(address indexed account, address sender, uint256 amount);
    event RewardIncrease(address indexed sender, uint256 amount);

    /**
     * @notice returns user's current reward balance
     */
    function depositRewards(address sender) external payable;

    /**
     * @dev in regards to this contract, this could just be earningsOf + sharesOf
     */
    function supplyOf(address account) external returns (uint256 res);

    function ownershipOfX128(address account) external view returns (uint256 res);

    function sharesOf(address account) external view returns (uint256 res);

    /**
     * @notice returns user's current reward balance
     * @return res
     */
    function totalSupply() external view returns (uint256 res);

    /**
     * @notice returns user's current reward balance
     * @return res
     */

    function totalShares() external view returns (uint256 res);
}
