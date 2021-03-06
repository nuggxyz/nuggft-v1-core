// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import "@nuggft-v1-core/test/main.sol";

abstract contract revert__NuggftV1Epoch is NuggftV1Test {
	/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        [E:0] - calculateSeed - "block hash does not exist"
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

	function test__revert__NuggftV1Epoch__calculateSeed__0x98__failNextEpoch() public {
		uint24 epoch = nuggft.epoch();
		ds.emit_log_uint(block.number);
		ds.emit_log_uint(block.number);

		ds.emit_log_bytes32(blockhash(nuggft.external__toStartBlock(epoch + 1)));
		forge.vm.expectRevert(hex"7e863b48_98");
		nuggft.external__calculateSeed(epoch + 1);
	}

	function test__revert__NuggftV1Epoch__calculateSeed__0x98__succeedCurrentBlock() public {
		nuggft.external__calculateSeed();
	}
}
