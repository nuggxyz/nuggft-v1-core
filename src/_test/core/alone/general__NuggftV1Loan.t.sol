// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "../../NuggftV1.test.sol";

import {ShiftLib} from "../../helpers/ShiftLib.sol";
import {NuggftV1Loan} from "../../../core/NuggftV1Loan.sol";

contract general__NuggftV1Loan is NuggftV1Test {
    uint24 internal LOAN_TOKENID;
    uint24 internal MINT_TOKENID;

    uint24 internal NUM = 4;

    function setUp() public {
        reset();

        LOAN_TOKENID = mintable(700);
        MINT_TOKENID = mintable(500);
    }

    function test__general__NuggftV1Loan__multirebalance() public {
        forge.vm.deal(users.frank, 1000000000 ether);

        forge.vm.startPrank(users.frank);

        nuggft.mint{value: 1 ether}(MINT_TOKENID);

        uint24[] memory list = new uint24[](NUM);

        for (uint24 i = 0; i < NUM; i++) {
            nuggft.mint{value: nuggft.msp()}(LOAN_TOKENID + i);
            nuggft.loan(array.b24(LOAN_TOKENID + i));
            list[i] = LOAN_TOKENID + i;
        }

        for (uint24 i = NUM; i < NUM * 2; i++) {
            nuggft.mint{value: nuggft.msp()}(LOAN_TOKENID + i);
        }

        jumpUp(33);

        nuggft.rebalance{value: nuggft.vfr(array.b24(LOAN_TOKENID))[0] * 1000}(list);
    }

    function test__general__NuggftV1Loan__rebalance() public {
        forge.vm.deal(users.frank, 1000000000 ether);

        forge.vm.startPrank(users.frank);

        nuggft.mint{value: 1 ether}(MINT_TOKENID);

        uint24[] memory list = new uint24[](NUM);

        for (uint24 i = 0; i < NUM; i++) {
            nuggft.mint{value: nuggft.msp()}(LOAN_TOKENID + i);
            nuggft.loan(array.b24(LOAN_TOKENID + i));
            list[i] = LOAN_TOKENID + i;
        }

        for (uint24 i = NUM; i < NUM * 2; i++) {
            nuggft.mint{value: nuggft.msp()}(LOAN_TOKENID + i);
        }

        jumpUp(44);

        for (uint24 i = 0; i < NUM; i++) {
            nuggft.rebalance{value: nuggft.vfr(array.b24(LOAN_TOKENID + i))[0]}(array.b24(LOAN_TOKENID + i));
        }
    }
}
