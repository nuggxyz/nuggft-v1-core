//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../utils/forge.sol";
import "../RiggedNuggftV1.sol";

import "../NuggftV1.test.sol";
import "../../interfaces/nuggftv1/INuggftV1.sol";

abstract contract base is INuggftV1Events {
    RiggedNuggftV1 nuggft;

    constructor() {
        nuggft = RiggedNuggftV1(global.getAddressSafe("RiggedNuggft"));
    }
}
