// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import "@nuggft-v1-core/test/main.sol";

abstract contract revert__claim__0xA0 is NuggftV1Test {
	// had to rig this one. the checks are too good
	function test__revert__claim__0xA0__fail__desc() public {
		uint24 tokenIdA = mintable(0);
		mintHelper(tokenIdA, users.frank, 1 ether);

		forge.vm.prank(users.frank);
		forge.vm.expectRevert(hex"7e863b48_a0");

		nuggft.claim(array.b24(tokenIdA), lib.sarrAddress(users.frank), array.b24(0), array.b16(0));
	}

	function test__revert__claim__0xA0__pass__desc() public {
		jumpStart();

		uint24 tokenId = nuggft.epoch();

		expect.offer().from(users.frank).value(1 ether).exec(tokenId);

		jumpUp(1);

		expect.claim().from(users.frank).exec(array.b24(tokenId), lib.sarrAddress(users.frank));
	}
}
