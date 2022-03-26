// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "../../../NuggftV1.test.sol";

abstract contract revert__sell__0x77 is NuggftV1Test {
    uint160 private token1 = mintable(222);

    function test__revert__sell__0x77__fail__desc() public {
        // mint
        expect.mint().from(users.frank).value(1 ether).exec(token1);

        expect.sell().from(users.frank).exec(token1, 2 ether);

        expect.offer().from(users.dee).value(nuggft.vfo(users.dee, token1)).exec(token1);

        expect.sell().from(users.dee).err(0x77).exec(token1, 3 ether);

        // bid

        jumpStart();

        expect.offer().from(users.dee).value(nuggft.vfo(users.dee, 3000)).exec(3000);

        expect.sell().from(users.dee).err(0x77).exec(3000, 3.5 ether);

        jumpUp(1);

        expect.sell().from(users.dee).err(0x77).exec(3000, 3.5 ether);
    }

    function test__revert__sell__0x77__pass__desc() public {
        jumpStart();
        // mint
        expect.mint().from(users.frank).value(1 ether).exec(token1);

        expect.sell().from(users.frank).exec(token1, 2 ether);

        expect.offer().from(users.dee).value(nuggft.vfo(users.dee, token1)).exec(token1);

        jumpSwap();

        expect.claim().from(users.dee).exec(lib.sarr160(token1), lib.sarrAddress(users.dee));

        expect.sell().from(users.dee).exec(token1, 3 ether);

        // bid

        jumpUp(1);

        uint160 token2 = nuggft.epoch();

        expect.offer().from(users.dee).value(3.2 ether).exec(token2);

        jumpUp(1);

        expect.claim().from(users.dee).exec(lib.sarr160(token2), lib.sarrAddress(users.dee));

        expect.sell().from(users.dee).exec(token2, 3.5 ether);
    }
}
