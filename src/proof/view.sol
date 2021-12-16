// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Global} from '../global/storage.sol';

import {EpochView} from '../epoch/view.sol';

import {ProofCore} from './core.sol';

import {ProofPure} from './pure.sol';

import {Proof} from './storage.sol';

library ProofView {
    function checkedProofOf(uint256 tokenId) internal view returns (uint256 res) {
        res = Proof.get(tokenId);
        require(res != 0, 'PROOF:PO:0');
    }

    function checkedProofOfIncludingPending(uint256 tokenId) internal view returns (uint256 res) {
        if (tokenId == EpochView.activeEpoch()) {
            (uint256 p, , , ) = pendingProof();
            return p;
        }
        res = Proof.get(tokenId);
        require(res != 0, 'PROOF:PO:0');
    }

    function hasProof(uint256 tokenId) internal view returns (bool res) {
        res = Proof.get(tokenId) != 0;
    }

    function parseProof(uint256 tokenId)
        internal
        view
        returns (
            uint256 proof,
            uint256[] memory defaultIds,
            uint256[] memory extraIds,
            uint256[] memory overrides
        )
    {
        proof = checkedProofOf(tokenId);

        return ProofPure.parseProofLogic(proof);

        // TODO HAVE TO IMPLEMENT OVERRIDES AND EXTRA IDS
        // defaultIds = new uint256[](8);

        // for (uint256 i = 1; i < 6; i++) {
        //     defaultIds[i] = (proof >> (4 + (ITEMID_SIZE * 6) + ITEMID_SIZE * (i - 1)));
        // }
    }

    function parsedProofOfIncludingPending(uint256 tokenId)
        internal
        view
        returns (
            uint256 proof,
            uint256[] memory defaultIds,
            uint256[] memory extraIds,
            uint256[] memory overrides
        )
    {
        proof = checkedProofOfIncludingPending(tokenId);

        return ProofPure.parseProofLogic(proof);

        // TODO HAVE TO IMPLEMENT OVERRIDES AND EXTRA IDS
        // defaultIds = new uint256[](8);

        // for (uint256 i = 1; i < 6; i++) {
        //     defaultIds[i] = (proof >> (4 + (ITEMID_SIZE * 6) + ITEMID_SIZE * (i - 1)));
        // }
    }

    function pendingProof()
        internal
        view
        returns (
            uint256 proof,
            uint256[] memory defaultIds,
            uint256[] memory extraIds,
            uint256[] memory overrides
        )
    {
        (uint256 seed, ) = EpochView.calculateSeed();

        seed = ProofCore.initFromSeed(seed);

        return ProofPure.parseProofLogic(seed);
    }
}
