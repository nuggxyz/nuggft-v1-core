// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import './interfaces/IxNUGG.sol';

import './libraries/StakeLib.sol';
import './libraries/EpochLib.sol';

/**
 * @title xNUGG
 * @author Nugg Labs - @danny7even & @dub6ix
 * @notice leggo
 */
contract xNUGG is IxNUGG, ERC20 {
    using Address for address payable;
    using StakeLib for StakeLib.Storage;
    using EpochLib for EpochLib.Storage;

    uint256 public immutable override genesis;

    StakeLib.Storage internal sl_state;

    EpochLib.Storage internal el_state;

    constructor() ERC20('Staked NUGG', 'xNUGG') {
        genesis = block.number;

        uint256 shares = sl_state.start(msg.sender);

        el_state.setSeed(block.number);

        emit Transfer(address(0), msg.sender, shares);
    }

    receive() external payable {
        el_state.setSeed(genesis);

        emit Receive(msg.sender, msg.value);
    }

    fallback() external payable {
        el_state.setSeed(genesis);

        emit Receive(msg.sender, msg.value);
    }

    function mint() public payable override {
        uint256 mintedShares = sl_state.add(msg.sender, msg.value);

        el_state.setSeed(genesis);

        emit Transfer(address(0), msg.sender, mintedShares);
    }

    function burn(uint256 shares) public override {
        uint256 eth = sl_state.sub(msg.sender, shares);

        el_state.setSeed(genesis);

        payable(msg.sender).sendValue(eth);

        emit Transfer(msg.sender, address(0), shares);
    }

    function _transfer(
        address from,
        address to,
        uint256 shares
    ) internal override {
        sl_state.move(from, to, shares);

        el_state.setSeed(genesis);

        emit Transfer(from, to, shares);
    }

    function epoch() public view override returns (uint256 res) {
        return EpochLib.activeEpoch(genesis);
    }

    /**
     * @dev in regards to this contract, this could just be earningsOf + sharesOf
     */
    function totalSupply() public view virtual override(ERC20, IxNUGG) returns (uint256 res) {
        res = sl_state.getActiveShares();
    }

    /**
     * @dev in regards to this contract, this could just be earningsOf + sharesOf
     */
    function balanceOf(address account) public view override(ERC20, IxNUGG) returns (uint256 res) {
        res = sl_state.getActiveSharesOf(account);
    }

    /**
     * @dev public wrapper for _shares - to save on gas
     */
    function totalEth() public view override returns (uint256 res) {
        res = StakeLib.getActiveEth();
    }

    /**
     * @dev public wrapper for _shares - to save on gas
     */
    function ethOf(address account) public view override returns (uint256 res) {
        res = sl_state.getActiveEthOf(account);
    }

    function ownershipOf(address account) public view override returns (uint256 res) {
        res = sl_state.getActiveOwnershipOf(account);
    }
}
