// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import './core/Stakeable.sol';
import './common/Escrowable.sol';

import './libraries/Exchange.sol';

import './interfaces/IxNUGG.sol';
import './erc20/ERC20.sol';
import './erc2981/ERC2981Receiver.sol';

/**
 * @title xNUGG
 * @author Nugg Labs - @danny7even & @dub6ix
 * @notice leggo
 */
contract xNUGG is IxNUGG, ERC20, ERC2981Receiver, Escrowable, Stakeable {
    Mutex local;

    using Address for address payable;

    constructor() ERC20('Staked NUGG', 'xNUGG') {
        local = initMutex();
    }

    function onERC2981Received(
        address operator,
        address from,
        address token,
        uint256 tokenId,
        address erc20,
        uint256 amount,
        bytes calldata data
    ) public payable override(ERC2981Receiver, IERC2981Receiver) lock(local) returns (bytes4) {
        if (msg_value() > 0) {
            uint256 tuck = (msg_value() * 1000) / 10000;
            _TUMMY.deposit{value: tuck}();
            Stakeable._onRoyaltyAdd(from, msg_value() - tuck);
            ERC20._mint(address(this), msg_value() - tuck);
        }

        return super.onERC2981Received(operator, from, token, tokenId, erc20, amount, data);
    }

    function deposit() public payable override(IxNUGG) {
        _deposit(msg_sender(), msg_value());
    }

    function withdraw(uint256 amount) public override(IxNUGG) {
        _withdraw(msg_sender(), amount);
    }

    function totalSupply() public view override(IxNUGG, ERC20, Stakeable) returns (uint256 res) {
        res = Stakeable.totalSupply();
    }

    function totalSupplyMinted() public view override returns (uint256 res) {
        res = ERC20.totalSupply();
    }

    function balanceOfMinted(address from) public view override returns (uint256 res) {
        res = ERC20.balanceOf(from);
    }

    function balanceOf(address from) public view override(IxNUGG, ERC20) returns (uint256 res) {
        res = Stakeable.supplyOf(from);
    }

    function _deposit(address to, uint256 amount) internal validateSupply {
        ERC20._mint(to, amount);
    }

    function _withdraw(address from, uint256 amount) internal validateSupply {
        ERC20._burn(from, amount);
        payable(from).sendValue(amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        if (to != address(0) && to != address(this)) Stakeable._onShareAdd(to, amount);
        if (from != address(0) && from != address(this)) Stakeable._onShareSub(from, amount);

        require(Stakeable.supplyOf(from) <= ERC20.balanceOf(from), 'NETH:ATT:0');
        require(Stakeable.supplyOf(to) <= ERC20.balanceOf(to), 'NETH:ATT:1');
    }

    function _realize(address account) internal {
        uint256 minted = ERC20.balanceOf(account);
        uint256 owned = Stakeable.supplyOf(account);

        if (owned > minted) {
            _assign(account, owned - minted);
            _onRealize(account, owned - minted);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override(ERC20) {
        if (to != address(0) && to != address(this)) _realize(to);
        if (from != address(0) && from != address(this)) _realize(from);
    }
}