// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "../../../NuggftV1.test.sol";

abstract contract revert__claim__0x76 is NuggftV1Test {
    function test__revert__claim__0x76__fail__desc() public {
        jump(3000);

        uint160 tokenId = nuggft.epoch();

        expect.offer().from(users.frank).exec(tokenId);

        expect.offer().from(users.dee).exec{value: 43 ether}(tokenId);

        jump(3001);

        expect.claim().from(users.frank).err(0x76).exec(array.b160(tokenId), array.bAddress(users.frank, users.dee));
    }

    function test__revert__claim__0x76__pass__desc() public {
        jump(3000);

        uint160 tokenId = nuggft.epoch();

        expect.offer().from(users.frank).exec(tokenId);

        expect.offer().from(users.dee).exec{value: 43 ether}(tokenId);

        jump(3001);

        expect.claim().from(users.frank).exec(array.b160(tokenId), array.bAddress(users.frank));
    }

    function test__revert__claim__0x76__pass__noFallback() public {
        jump(3000);

        uint160 tokenId = nuggft.epoch();

        expect.offer().from(ds.noFallback).exec{value: 22 ether}(tokenId);

        expect.offer().from(users.dee).exec{value: 43 ether}(tokenId);

        jump(3001);

        expect.claim().from(ds.noFallback).exec(array.b160(tokenId), array.bAddress(ds.noFallback));
    }

    function test__revert__claim__0x76__pass__hasFallback() public {
        jump(3000);

        uint160 tokenId = nuggft.epoch();

        expect.offer().from(ds.hasFallback).exec{value: 22 ether}(tokenId);

        expect.offer().from(users.dee).exec{value: 43 ether}(tokenId);

        jump(3001);

        expect.claim().from(ds.hasFallback).exec(array.b160(tokenId), array.bAddress(ds.hasFallback));
    }
}
