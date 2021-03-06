// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import "@nuggft-v1-core/test/main.sol";

contract blackbox__offer is NuggftV1Test {
	function setUp() public {
		reset();
	}

	function symbo__1(address user, uint24 token) public {
		forge.vm.assume(nuggft.agencyOf(token) != 0);
		expect.offer().from(user).exec{value: nuggft.msp()}(token);
	}
}
