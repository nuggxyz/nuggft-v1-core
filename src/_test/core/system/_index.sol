// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "./system__NuggftV1Loan.t.sol";
import "./system__NuggftV1Swap.t.sol";
import "./system__NuggftV1Epoch.t.sol";
import "./system__one.t.sol";

contract System is system__NuggftV1Swap, system__one, system__NuggftV1Loan, system__NuggftV1Epoch {
    function setUp() public {
        resetManual(dub6ix, 1 ether);

        forge.vm.deal(users.frank, 90000 ether);

        forge.vm.deal(users.dee, 90000 ether);

        forge.vm.deal(users.mac, 90000 ether);

        forge.vm.deal(users.dennis, 90000 ether);

        forge.vm.deal(users.charlie, 90000 ether);

        forge.vm.deal(users.safe, 90000 ether);
    }
}
