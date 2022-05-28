// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import "../../../NuggftV1.test.sol";

abstract contract revert__mint__0x65 is NuggftV1Test {
    function test__revert__mint__0x65__fail__desc() public {
        expect.mint().from(users.frank).err(0x65).exec{value: nuggft.msp()}(mintable(0) - 1);

        // expect.mint().from(users.frank).err(0x65).exec(uint32(MAX_TOKENS) + 1);
    }

    function test__revert__mint__0x65__pass__desc() public {
        expect.mint().from(users.frank).exec{value: nuggft.msp()}(mintable(0));

        expect.mint().from(users.frank).exec{value: nuggft.msp()}(mintable(1000));
    }
}
