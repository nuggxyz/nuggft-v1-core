// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import '../../NuggftV1.test.sol';

contract txgas__NuggftV1Loan is NuggftV1Test {
    uint160 internal constant LOAN_TOKENID = 1499;
    uint160 internal constant REBALANCE_TOKENID = 1498;
    uint160 internal constant LIQUIDATE_TOKENID = 1497;

    function setUp() public {
        reset();
        // forge.vm.roll(21000);

        forge.vm.deal(users.frank, 40000 ether);

        forge.vm.startPrank(users.frank);

        nuggft.mint{value: 100 ether}(LOAN_TOKENID);
        nuggft.mint{value: 100 ether}(REBALANCE_TOKENID);
        nuggft.loan(REBALANCE_TOKENID);

        forge.vm.roll(2400);

        nuggft.mint{value: 100 ether}(LIQUIDATE_TOKENID);

        nuggft.loan(LIQUIDATE_TOKENID);
    }

    function test__txgas__NuggftV1Loan__loan() public {
        nuggft.loan(LOAN_TOKENID);
    }

    function test__txgas__NuggftV1Loan__mutlirebalance() public {
        uint160[] memory a = new uint160[](1);
        a[0] = REBALANCE_TOKENID;
        nuggft.multirebalance{value: 200 ether}(a);
    }

    function test__txgas__NuggftV1Loan__rebalance() public {
        nuggft.rebalance{value: 200 ether}(REBALANCE_TOKENID);
    }

    function test__txgas__NuggftV1Loan__liquidate() public {
        nuggft.liquidate{value: 200 ether}(LIQUIDATE_TOKENID);
    }
}