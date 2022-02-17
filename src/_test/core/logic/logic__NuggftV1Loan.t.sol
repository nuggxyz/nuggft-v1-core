// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import '../../NuggftV1.test.sol';

import {ShiftLib} from '../../../libraries/ShiftLib.sol';
import {NuggftV1Loan} from '../../../core/NuggftV1Loan.sol';
import {NuggftV1Token} from '../../../core/NuggftV1Token.sol';

contract logic__NuggftV1Loan is NuggftV1Test, NuggftV1Loan {
    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                  overrides
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {}

    function trustedMint(uint160 tokenId, address to) external payable override requiresTrust {}

    function mint(uint160 tokenId) public payable override {}

    function burn(uint160 tokenId) public override {}

    function migrate(uint160 tokenId) public override {}

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                tx gas
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    function test__logic__NuggftV1Loan__calc__tx__gas() public pure {
        calc(type(uint96).max, type(uint96).max);
    }

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                   calc
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    function safe__calc__0(uint96 principal, uint96 activeEps) internal pure returns (uint96 fee, uint96 earned) {
        fee = activeEps - principal;

        uint96 checkfee = (principal / REBALANCE_FEE_BPS);

        if (fee > checkfee) {
            earned = fee - checkfee;
            fee = checkfee;
        }
    }

    function safe__calc__1(uint96 principal, uint96 activeEps) internal pure returns (uint96 fee, uint96 earned) {
        fee = activeEps - principal;

        uint96 checkFee = (principal / REBALANCE_FEE_BPS);

        if (activeEps - checkFee > principal) {
            fee = checkFee;
            uint96 toLiquidate = principal + fee;
            earned = activeEps - toLiquidate;
        }
    }

    function safe__calc__2(uint96 principal, uint96 activeEps) internal pure returns (uint96 fee, uint96 earned) {
        fee = activeEps - principal;

        uint96 checkFee = (principal / REBALANCE_FEE_BPS);

        if (activeEps - checkFee > principal) {
            fee = checkFee;
        }

        earned = activeEps - (principal + fee);
    }

    function test__logic__NuggftV1Loan__calc__gas() public pure {
        calc(type(uint96).max, type(uint96).max);
    }

    function test__logic__NuggftV1Loan__safe__calc__0__gas() public pure {
        safe__calc__0(type(uint96).max, type(uint96).max);
    }

    function test__logic__NuggftV1Loan__safe__calc__1__gas() public pure {
        safe__calc__1(type(uint96).max, type(uint96).max);
    }

    function test__logic__NuggftV1Loan__safe__calc__2__gas() public pure {
        safe__calc__2(type(uint96).max, type(uint96).max);
    }

    function test__logic__NuggftV1Loan__calc__safe(uint96 principal, uint96 activeEps) public {
        if (principal > activeEps) return;

        (uint256 rb, uint96 rc) = calc(principal, activeEps);

        (uint256 sb, uint96 sc) = safe__calc__0(principal, activeEps);

        assertEq(rb, sb);
        assertEq(rc, sc);

        (uint256 sb1, uint96 sc1) = safe__calc__1(principal, activeEps);

        assertEq(rb, sb1);
        assertEq(rc, sc1);

        (uint256 sb2, uint96 sc2) = safe__calc__2(principal, activeEps);

        assertEq(rb, sb2);
        assertEq(rc, sc2);
    }

    function test__logic__NuggftV1Loan__calc__cerror_4() public {
        // forge.vm.expectRevert(hex'69');
        require(true, hex'69');
    }
}
