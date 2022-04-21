// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface INuggftV1Epoch {
    function epoch() external view returns (uint24 res);
}
