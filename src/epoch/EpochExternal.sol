// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IEpochExternal} from '../interfaces/INuggFT.sol';

import {EpochView} from '../epoch/EpochView.sol';

abstract contract EpochExternal is IEpochExternal {
    function epoch() external view override returns (uint32) {
        return EpochView.activeEpoch();
    }
}