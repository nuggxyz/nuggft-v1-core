// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../../NuggftV1.test.sol";

contract general__premint2 is NuggftV1Test {
    function setUp() public {
        reset();
    }

    function test__premint2() public {
        uint24 token1 = nuggft.epoch();

        expect.offer().from(users.dee).exec{value: nuggft.msp()}(token1);

        jumpSwap();

        expect.claim().from(users.dee).exec(token1, users.dee);

        (uint24 token, ) = nuggft.premintTokens();

        forge.vm.startPrank(users.frank);
        forge.vm.deal(users.frank, 5 ether);

        uint16 item = nuggft.floop(token)[9];

        nuggft.offer{value: 1 ether}(token);

        forge.vm.stopPrank();

        expect.offer().from(users.dee).exec{value: nuggft.vfo(token1, token, item)}(token1, token, item);
        expect.claim().from(users.frank).exec(token, token, item);

        jumpSwap();

        expect.claim().from(users.dee).exec(token, token1, item);
    }
}