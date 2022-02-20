// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import {IERC721, IERC165, IERC721Metadata} from './interfaces/IERC721.sol';

import {NuggftV1Loan} from './core/NuggftV1Loan.sol';
import {NuggftV1Dotnugg} from './core/NuggftV1Dotnugg.sol';

import {INuggftV1Migrator} from './interfaces/nuggftv1/INuggftV1Migrator.sol';

import {IDotnuggV1} from './interfaces/dotnugg/IDotnuggV1.sol';
import {IDotnuggV1Safe} from './interfaces/dotnugg/IDotnuggV1Safe.sol';

import {INuggftV1Token} from './interfaces/nuggftv1/INuggftV1Token.sol';
import {INuggftV1Stake} from './interfaces/nuggftv1/INuggftV1Stake.sol';
import {INuggftV1Proof} from './interfaces/nuggftv1/INuggftV1Proof.sol';

import {INuggftV1} from './interfaces/nuggftv1/INuggftV1.sol';

import {data as nuggs} from './_data/nuggs.data.sol';

/// @title NuggftV1
/// @author nugg.xyz - danny7even & dub6ix
contract NuggftV1 is IERC721Metadata, NuggftV1Loan {
    constructor(address dotnugg) NuggftV1Dotnugg(dotnugg) {}

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId || //
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /// @inheritdoc IERC721Metadata
    function name() public pure override returns (string memory) {
        return 'Nugg Fungible Token V1';
    }

    /// @inheritdoc IERC721Metadata
    function symbol() public pure override returns (string memory) {
        return 'NUGGFT';
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory res) {
        // prettier-ignore
        res = string(
            dotnuggV1.encodeJsonAsBase64(
                abi.encodePacked(
                    '{"name":"',         name(),
                    '","description":"', symbol(),
                    '","image":"',       imageURI(tokenId),
                    '","properites":',   dotnuggV1.props(
                        proofs[uint160(tokenId)],
                        ['base', 'eyes', 'mouth', 'hair', 'hat', 'background', 'scarf', 'held']
                    ),
                    '}'
                )
            )
        );
    }

    /// @inheritdoc INuggftV1Proof
    function imageURI(uint256 tokenId) public view override returns (string memory res) {
        res = dotnuggV1.exec(proofs[uint160(tokenId)], true);
    }

    /// @inheritdoc INuggftV1Token
    function mint(uint160 tokenId) public payable override {
        require(
            tokenId <= UNTRUSTED_MINT_TOKENS + TRUSTED_MINT_TOKENS && //
                tokenId >= TRUSTED_MINT_TOKENS,
            hex'65'
        );
        if (tokenId == 600) {
            assembly {
                mstore(0x00, Panic__Sig)
                mstore(0x04, 0x65)
                revert(0x00, 0x24)
            }
        }

        addStakedShareFromMsgValue();

        mint(msg.sender, tokenId);
    }

    /// @inheritdoc INuggftV1Token
    function trustedMint(uint160 tokenId, address to) external payable override requiresTrust {
        require(tokenId < TRUSTED_MINT_TOKENS && tokenId != 0, hex'66');

        addStakedShareFromMsgValue();

        mint(to, tokenId);
    }

    function mint(address to, uint160 tokenId) internal {
        uint256 randomEnough;

        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, agency.slot)

            let agency__sptr := keccak256(0x00, 0x40)

            if iszero(iszero(sload(agency__sptr))) {
                mstore8(0x00, Error__P__0x80__TokenDoesExist)
                revert(0x00, 0x01)
            }

            // ========= memory ==========
            //   0x00: tokenId
            //   0x20: blockhash(((blocknum - 2) / 16) * 16)
            // ===========================
            mstore(0x20, blockhash(shl(shr(sub(number(), 2), 4), 4)))

            randomEnough := keccak256(0x00, 0x40)

            // update agency to reflect the new leader
            // ====agency[tokenId]====
            //     flag  = OWN(0x01)
            //     epoch = 0
            //     eth   = 0
            //     addr  = to
            // =======================
            let agency__cache := or(shl(254, 0x01), to)

            sstore(agency__sptr, agency__cache)

            log4(0x00, 0x00, Event__Transfer, 0, to, tokenId)

            mstore(0x00, tokenId)
            mstore(0x20, callvalue())
            log1(0x00, 0x40, Event__Mint)
        }

        proofs[tokenId] = initFromSeed(randomEnough);
    }

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                BURN/MIGRATE
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    /// @inheritdoc INuggftV1Stake
    function burn(uint160 tokenId) external {
        uint96 ethOwed = subStakedShare(tokenId);

        payable(msg.sender).transfer(ethOwed);

        emit Burn(tokenId, msg.sender, ethOwed);
    }

    /// @inheritdoc INuggftV1Stake
    function migrate(uint160 tokenId) external {
        require(migrator != address(0), hex'74');

        // stores the proof before deleting the nugg
        uint256 proof = proofOf(tokenId);

        uint96 ethOwed = subStakedShare(tokenId);

        INuggftV1Migrator(migrator).nuggftMigrateFromV1{value: ethOwed}(tokenId, proof, msg.sender);

        emit MigrateV1Sent(migrator, tokenId, proof, msg.sender, ethOwed);
    }

    /// @notice removes a staked share from the contract,
    /// @dev this is the only way to remove a share
    /// @dev caculcates but does not handle dealing the eth - which is handled by the two helpers above
    /// @dev ensures the user is the owner of the nugg
    /// @param tokenId the id of the nugg being unstaked
    /// @return ethOwed -> the amount of eth owed to the unstaking user - equivilent to "ethPerShare"
    function subStakedShare(uint160 tokenId) internal returns (uint96 ethOwed) {
        require(isOwner(msg.sender, tokenId), hex'73');

        uint256 cache = stake;

        // handles all logic not related to staking the nugg
        delete agency[tokenId];
        delete proofs[tokenId];

        emit Transfer(msg.sender, address(0), tokenId);

        ethOwed = calculateEthPerShare(cache);

        /// TODO - test migration
        // assert(cache.shares() >= 1);
        // assert(cache.staked() >= ethOwed);

        cache -= 1 << 160;
        cache -= ethOwed << 96;

        stake = cache;

        emit Stake(bytes32(cache));
    }
}
