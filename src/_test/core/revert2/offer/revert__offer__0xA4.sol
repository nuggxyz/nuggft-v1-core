// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "../../../NuggftV1.test.sol";

abstract contract revert__offer__0xA4 is NuggftV1Test {
    uint24 private token1 = mintable(32);

    function test__revert__offer__0xA4__fail__desc() public {
        jumpStart();

        expect.mint().from(users.frank).value(.5 ether).exec(token1);

        expect.sell().from(users.frank).exec(token1, .5 ether);

        expect.offer().from(users.mac).value(.6 ether).exec(token1);

        jumpSwap();

        expect.offer().from(users.dee).value(0.8 ether).err(0xA4).exec(token1);
    }

    function test__revert__offer__0xA4__pass__desc() public {
        jumpStart();

        expect.mint().from(users.frank).value(.5 ether).exec(token1);

        expect.sell().from(users.frank).exec(token1, .5 ether);

        expect.offer().from(users.mac).value(.6 ether).exec(token1);

        expect.offer().from(users.dee).value(0.8 ether).exec(token1);
    }
}
