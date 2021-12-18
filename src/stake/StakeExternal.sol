// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {SafeCastLib} from '../libraries/SafeCastLib.sol';

import {IStakeExternal} from '../interfaces/INuggFT.sol';

import {StakeView} from './StakeView.sol';
import {StakeTrust} from './StakeTrust.sol';
import {StakeCore} from './StakeCore.sol';

abstract contract StakeExternal is IStakeExternal, StakeTrust {
    using SafeCastLib for uint256;

    function extractProtocolEth() external override requiresTrust {
        StakeCore.trustedExtractProtocolEth();
    }

    function withdrawStake(uint160 tokenId) external override {
        StakeCore.subStakedSharePayingSender(tokenId);
    }

    function totalStakedShares() external view override returns (uint64 res) {
        res = StakeView.getActiveStakedShares();
    }

    function totalStakedEth() external view override returns (uint96 res) {
        res = StakeView.getActiveStakedEth();
    }

    function activeEthPerShare() external view override returns (uint96 res) {
        res = StakeView.getActiveEthPerShare();
    }

    function totalProtocolEth() external view override returns (uint96 res) {
        res = StakeView.getActiveProtocolEth();
    }

    function totalSupply() external view override returns (uint256 res) {
        res = StakeView.getActiveStakedShares();
    }
}