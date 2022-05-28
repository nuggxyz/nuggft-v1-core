// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import "../../../NuggftV1.test.sol";

abstract contract revert__rebalance__0xAA is NuggftV1Test {
    function test__revert__rebalance__0xAA__fail__desc() public {
        uint24 TOKEN1 = mintable(0);

        expect.mint().from(users.frank).value(20 ether).exec(TOKEN1);

        expect.loan().from(users.frank).exec(array.b24(TOKEN1));

        expect.rebalance().from(users.frank).value(nuggft.vfr(array.b24(TOKEN1))[0] - 1).err(0xAA).exec(array.b24(TOKEN1));
    }

    function test__revert__rebalance__0xAA__pass__desc() public {
        uint24 TOKEN1 = mintable(0);

        expect.mint().from(users.frank).value(20 ether).exec(TOKEN1);

        expect.loan().from(users.frank).exec(array.b24(TOKEN1));

        expect.rebalance().from(users.frank).value(nuggft.vfr(array.b24(TOKEN1))[0]).exec(array.b24(TOKEN1));
    }
}
