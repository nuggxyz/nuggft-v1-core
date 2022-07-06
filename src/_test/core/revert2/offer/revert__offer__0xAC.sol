// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import "../../../NuggftV1.test.sol";

abstract contract revert__offer__0xAC is NuggftV1Test {
	function test__revert__offer__0xAC__pass__multioffer() public {
		uint24 franksNugg = mintable(55);

		mintHelper(franksNugg, users.frank, nuggft.vfo(users.frank, franksNugg));

		uint24 token1 = mintable(32);

		uint16[16] memory floop1 = xnuggft.floop(token1);

		uint16 item = floop1[9];

		uint24 token2 = findNewNuggWithItem(item, token1);

		expect.offer().from(users.frank).exec{value: nuggft.vfo(users.frank, token1)}(token1);
		expect.offer().from(users.frank).exec{value: nuggft.vfo(users.frank, token2)}(token2);

		// offer on an item
		expect.offer().from(users.frank).err(0x00).exec{value: nuggft.vfo(franksNugg, token1, item)}(franksNugg, token1, item);
		expect.offer().from(users.frank).err(0xAC).exec{value: nuggft.vfo(franksNugg, token2, item)}(franksNugg, token2, item);
		jumpUp(1);
		expect.offer().from(users.frank).err(0x00).exec{value: nuggft.vfo(franksNugg, token1, item)}(franksNugg, token1, item);
		expect.offer().from(users.frank).err(0xB4).exec{value: nuggft.vfo(franksNugg, token2, item)}(franksNugg, token2, item);
		jumpUp(1);
		expect.offer().from(users.frank).err(0x99).exec{value: nuggft.vfo(franksNugg, token1, item)}(franksNugg, token1, item);
		expect.offer().from(users.frank).err(0x00).exec{value: nuggft.vfo(franksNugg, token2, item)}(franksNugg, token2, item);
	}
}
