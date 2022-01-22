// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {NuggftV1ItemSwap} from './NuggftV1ItemSwap.sol';
import {INuggftV1Swap} from '../interfaces/nuggftv1/INuggftV1Swap.sol';
import {NuggftV1Stake} from './NuggftV1Stake.sol';
import {CastLib} from '../libraries/CastLib.sol';
import {TransferLib} from '../libraries/TransferLib.sol';

import {NuggftV1AgentType} from '../types/NuggftV1AgentType.sol';
import '../_test/utils/forge.sol';

/// @notice mechanism for trading of nuggs between users (and items between nuggs)
/// @dev Explain to a developer any extra details
abstract contract NuggftV1Swap is INuggftV1Swap, NuggftV1ItemSwap {
    using NuggftV1AgentType for uint256;

    mapping(uint160 => mapping(address => uint256)) offers;

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                  offer
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    /// @inheritdoc INuggftV1Swap
    function offer(uint160 tokenId) external payable override {
        uint256 agency__slot;

        uint256 agency__cache;
        uint256 next;

        uint256 active = epoch();
        uint256 ptr;

        assembly {
            next := div(callvalue(), LOSS)

            ptr := mload(0x40)

            mstore(ptr, tokenId)
            mstore(add(ptr, 0x20), agency.slot)

            agency__slot := keccak256(ptr, 0x40)
            agency__cache := sload(agency__slot)

            mstore(0x40, add(ptr, 0x40))
        }

        // make sure user is not the owner of swap
        // we do not know how much to give them when they call "claim" otherwise

        if (active == tokenId && agency__cache == 0) {
            addStakedShareFromMsgValue();

            setProofFromEpoch(tokenId);

            assembly {
                log4(0x00, 0x00, TRANSFER, 0, address(), tokenId)
            }
        } else {
            uint256 last;

            assembly {
                // ensure that the agency flag is "SWAP" (0x01)
                if iszero(eq(shr(254, agency__cache), 0x01)) {
                    mstore8(0x0, 0x24) // ERR:0x24
                    revert(0x00, 0x01)
                }

                // calculate and store the offer[tokenId]__slot
                // tokenId already exists at ptr
                mstore(add(ptr, 0x20), offers.slot)
                mstore(add(ptr, 0x20), keccak256(ptr, 0x40))

                let lastLead := shr(96, shl(96, agency__cache))

                let offer__cache := agency__cache

                if iszero(eq(caller(), lastLead)) {
                    mstore(ptr, caller())
                    offer__cache := sload(keccak256(ptr, 0x40))
                }

                // check to see if user has offered by checking if cache != 0
                if iszero(iszero(offer__cache)) {
                    // check to see if the epoch from offer__cache has expired
                    // this accomplishes two important goals:
                    // 1. forces user to claim previous swap before acting on this one
                    // 2. prevents owner from offering on their own swap before someone else has
                    if lt(shr(232, shl(2, offer__cache)), active) {
                        mstore8(0x0, 0x0F) // ERR:0x0F
                        revert(0x00, 0x01)
                    }
                }

                // check to see if the epoch stored in agency__cache == 0
                switch iszero(shr(232, shl(2, agency__cache)))
                // if so, we know this swap has not yet been offered on
                // we update the epoch and we transfer the token to the contract
                case 1 {
                    active := add(active, SALE_LEN)

                    agency__cache := or(agency__cache, shl(230, active))

                    log4(0x00, 0x00, TRANSFER, lastLead, address(), tokenId)
                }
                // otherwise we validate the epoch to ensure the swap is still active
                default {
                    let agency__epoch := shr(232, shl(2, agency__cache))

                    if lt(agency__epoch, active) {
                        mstore8(0x0, 0x2F) // ERR:0x2F
                        revert(0x00, 0x01)
                    }

                    active := agency__epoch
                }

                last := shr(186, shl(26, agency__cache))
                next := add(shr(186, shl(26, offer__cache)), next)

                if gt(div(mul(last, 10200), 10000), next) {
                    mstore8(0x0, 0x72)
                    revert(0x00, 0x01)
                }

                last := mul(sub(next, last), LOSS)

                // record agency so we know how much to repay previous leader
                mstore(ptr, shr(96, shl(96, agency__cache)))
                sstore(keccak256(ptr, 0x40), agency__cache)
            }

            addStakedEth(uint96(last));
        }

        assembly {
            // update agency to reflect the new leader
            //
            // agency[tokenId] = {
            //     flag  = SWAP
            //     epoch = active or active +1
            //     eth   = new highest value / 10**8
            //     addr  = msg.sender
            // }
            agency__cache := or(shl(254, 0x01), or(shl(230, active), or(shl(160, next), caller())))
            sstore(agency__slot, agency__cache)
        }

        emit Offer(tokenId, bytes32(agency__cache));
    }

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                  claim
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    /// @inheritdoc INuggftV1Swap
    function claim(uint160[] calldata tokenIds, address[] calldata accounts) external override {
        uint256 active = epoch();

        assembly {
            let ptr := mload(0x40)
            let acc := 0

            let len := calldataload(sub(tokenIds.offset, 0x20))

            if iszero(eq(len, calldataload(sub(accounts.offset, 0x20)))) {
                // arrays are not the same length
                mstore8(0x0, 0x99)
                // calldatacopy(0x00, tokenIds.offset, 0x32)
                revert(0x00, 0x01)
            }

            mstore(add(ptr, 0x20), agency.slot)

            mstore(add(ptr, 0x60), offers.slot)

            for {
                let i := 0
                let tokenPtr := tokenIds.offset
                let accntPtr := accounts.offset
            } lt(i, len) {
                i := add(i, 1)
                tokenPtr := add(tokenPtr, 0x20)
                accntPtr := add(accntPtr, 0x20)
            } {
                let tokenId := calldataload(tokenPtr)

                let addr := calldataload(accntPtr)

                mstore(ptr, tokenId)
                let agency__slo := keccak256(ptr, 0x40)
                let agency__cache := sload(agency__slo)

                mstore(add(ptr, 0x40), tokenId)
                let offerSlot := keccak256(add(ptr, 0x40), 0x40)
                mstore(add(ptr, 0x40), addr)
                mstore(add(ptr, 0x60), offerSlot)
                offerSlot := keccak256(add(ptr, 0x40), 0x40)

                switch eq(addr, shr(96, shl(96, agency__cache)))
                case 1 {
                    let real := shr(232, shl(2, agency__cache))

                    // require "isOwner" or "isOver"
                    // == require(real == 0 || active > real)
                    if and(iszero(iszero(real)), iszero(gt(active, real))) {
                        mstore8(0x0, 0x67)
                        revert(0x00, 0x01)
                    }

                    sstore(offerSlot, 0)

                    sstore(agency__slo, or(caller(), shl(254, 0x3)))
                }
                default {
                    let offer__cache := sload(offerSlot)

                    if iszero(offer__cache) {
                        mstore8(0x0, 0x2E)
                        revert(0x00, 0x01)
                    }

                    // update state before we potentially send value
                    sstore(offerSlot, 0)

                    switch eq(caller(), addr)
                    case 1 {
                        acc := add(acc, shr(186, shl(26, offer__cache)))
                    }
                    default {
                        // let real := shr(232, shl(2, offer__cache))

                        // if swap is active, require the user is the caller
                        if gt(active, shr(232, shl(2, offer__cache))) {
                            if iszero(eq(caller(), addr)) {
                                mstore8(0x0, 0x68)
                                revert(0x00, 0x01)
                            }
                        }

                        let amt := mul(shr(186, shl(26, offer__cache)), LOSS)

                        if iszero(call(gas(), addr, amt, 0, 0, 0, 0)) {
                            mstore8(0x0, 0x91)
                            revert(0x00, 0x01)
                        }
                    }
                }

                log3(0x00, 0x00, CLAIM, tokenId, addr)
            }

            if iszero(acc) {
                return(0, 0)
            }
            if iszero(call(gas(), caller(), mul(acc, LOSS), 0, 0, 0, 0)) {
                mstore8(0x0, 0x92)
                revert(0x00, 0x01)
            }
        }
    }

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                  sell
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    /// @inheritdoc INuggftV1Swap
    function sell(uint160 tokenId, uint96 floor) external override {
        require(isOwner(msg.sender, tokenId), hex'2A');

        require(floor >= eps(), hex'2B');

        uint256 updatedAgency;

        assembly {
            // updatedAgency = [ flag: SWAP | epoch: 0 | eth: floor/10**8 | addr: msg.sender ]
            updatedAgency := or(shl(254, 0x1), or(shl(230, 0), or(shl(160, div(floor, LOSS)), caller())))

            mstore(0, tokenId)
            mstore(0x20, agency.slot)
            sstore(keccak256(0, 64), updatedAgency)
        }

        emit Sell(tokenId, bytes32(updatedAgency));
    }

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                    view
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    // / @inheritdoc INuggftV1Swap
    function valueForOffer(address sender, uint160 tokenId)
        external
        view
        override
        returns (
            bool canOffer,
            uint96 nextSwapAmount,
            uint96 senderCurrentOffer
        )
    {
        canOffer = true;

        uint256 swapData = agency[tokenId];
        uint24 activeEpoch = epoch();

        uint256 offerData;

        if (uint160(sender) == uint160(swapData)) {
            offerData = swapData;
        } else {
            offerData = offers[tokenId][sender];
        }

        if (swapData == 0) {
            if (activeEpoch == tokenId) {
                // swap is minting
                nextSwapAmount = NuggftV1AgentType.compressEthRoundUp(msp());
            } else {
                // swap does not exist
                return (false, 0, 0);
            }
        } else {
            if (swapData.epoch() == 0 && offerData == swapData) canOffer = false;

            senderCurrentOffer = offerData.eth();

            nextSwapAmount = swapData.eth();

            if (nextSwapAmount < eps()) {
                nextSwapAmount = eps();
            }
        }

        if (nextSwapAmount != 0) {
            nextSwapAmount = NuggftV1AgentType.addIncrement(nextSwapAmount);
        }
    }
}

//  assembly {
//                 let ptr := mload(0x40)
//                 // Store num in memory scratch space (note: lookup "free memory pointer" if you need to allocate space)
//                 mstore(ptr, tokenId)
//                 // Store slot number in scratch space after num
//                 mstore(add(ptr, 0x20), agency.slot)
//                 // Create hash from previously stored num and slot
//                 let hash := keccak256(0, 64)
//                 // Load mapping value using the just calculated hash
//                 cache := sload(hash)
//             }
//         } else {

// function offerItem2(
//     uint160 buyerTokenId,
//     uint160 sellerTokenId,
//     uint16 itemId
// ) external payable {
//     require(isAgent(msg.sender, buyerTokenId), hex'26');

//     uint256 loc = itemId;

//     uint256 swapData;

//     uint24 active = epoch();

//     uint256 next = genesis;

//     assembly {
//         next := div(callvalue(), LOSS)

//         loc := or(shl(160, loc), sellerTokenId)

//         mstore(0x00, loc)
//         mstore(0x20, itemAgency.slot)

//         loc := keccak256(0x00, 0x40)

//         swapData := sload(loc)
//     }

//     require(swapData != 0, hex'22');

//     uint256 offerData = swapData;

//     if (buyerTokenId != uint160(swapData)) {
//         offerData = itemOffers[encItemId(sellerTokenId, itemId)][buyerTokenId];
//     }

//     if (offerData != 0) {
//         // forces user to claim previous swap before acting on this one
//         // prevents owner from COMMITTING on their own swap - not offering
//         require(offerData.epoch() >= active, hex'27');
//     }

//     if (offerData == 0 && (swapData.epoch() == 0)) {
//         // require(msg.value >= eps(), hex'25');

//         unchecked {
//             active++;
//         }

//         itemOffers[encItemId(sellerTokenId, itemId)][uint160(swapData)] = swapData | (uint256(active) << 230);
//     } else {
//         assembly {
//             let swapData__epoch := shr(232, shl(2, swapData))

//             if lt(swapData__epoch, active) {
//                 mstore8(0x0, 0x2f)
//                 revert(0x00, 0x01)
//             }

//             active := swapData__epoch
//         }

//         itemOffers[encItemId(sellerTokenId, itemId)][uint160(swapData)] = swapData;
//     }

//     uint256 last;

//     uint256 updatedAgency;

//     assembly {
//         last := shr(186, shl(26, swapData))
//         next := add(shr(186, shl(26, offerData)), next)

//         // ensure next >= (last + 2%)
//         if gt(div(mul(last, 10200), 10000), next) {
//             mstore(0x00, 0x28)
//             revert(0x1F, 0x01)
//         }

//         last := mul(sub(next, last), LOSS)

//         updatedAgency := or(buyerTokenId, or(shl(160, next), or(shl(230, active), shl(254, 0x1))))

//         sstore(loc, updatedAgency)
//     }

//     addStakedEth(uint96(last));

//     emit OfferItem(encItemId(sellerTokenId, itemId), bytes32(updatedAgency));
// }

// function _claim(uint160 tokenId) internal returns (uint96 value) {
//     uint256 loc;

//     uint256 swapData;

//     assembly {
//         let ptr := mload(0x40)
//         mstore(ptr, tokenId)
//         mstore(add(ptr, 0x20), agency.slot)

//         loc := keccak256(ptr, 64)
//         swapData := sload(loc)
//     }

//     // require(swapData != 0, hex'22');

//     uint256 offerData;

//     if (uint160(msg.sender) == uint160(swapData)) {
//         offerData = swapData;
//     } else {
//         offerData = offers[tokenId][msg.sender];
//     }

//     require(offerData != 0, hex'2E');

//     delete offers[tokenId][msg.sender];

//     // if user is the leader
//     if (uint160(offerData) == uint160(swapData)) {
//         uint24 active = epoch();

//         assembly {
//             let real := shr(232, shl(2, swapData))

//             // require "isOwner" or "isOver"
//             // == require(real == 0 || active > real)
//             if and(iszero(iszero(real)), iszero(gt(active, real))) {
//                 mstore(0x00, 0x67)
//                 revert(31, 0x01)
//             }

//             sstore(loc, or(caller(), shl(254, 0x3)))
//         }

//         emit Transfer(address(this), msg.sender, tokenId);
//     } else {
//         assembly {
//             value := mul(and(shr(offerData, 160), sub(shl(70, 1), 1)), LOSS)
//         }
//     }

//     emit Claim(tokenId, msg.sender);
// }

// /// @inheritdoc INuggftV1Swap
// function claimItem(
//     uint160 buyerTokenId,
//     uint160 sellerTokenId,
//     uint16 itemId
// ) public override {
//     uint96 value = _claimItem(buyerTokenId, sellerTokenId, itemId);

//     assembly {
//         if iszero(value) {
//             return(0, 0)
//         }
//         if iszero(call(gas(), caller(), value, 0, 0, 0, 0)) {
//             mstore(0, 0x01)
//             revert(0x1F, 0x01)
//         }
//     }
// }

// function _claimItem(
//     uint160 buyerTokenId,
//     uint160 sellerTokenId,
//     uint16 itemId
// ) internal returns (uint96 value) {
//     require(isAgent(msg.sender, buyerTokenId), hex'29');

//     uint256 swapData = itemAgency[encItemId(sellerTokenId, itemId)];

//     // require(swapData != 0, hex'22');

//     uint256 offerData;

//     if (buyerTokenId == uint160(swapData)) {
//         offerData = swapData;
//     } else {
//         offerData = itemOffers[encItemId(sellerTokenId, itemId)][buyerTokenId];
//     }

//     delete itemOffers[encItemId(sellerTokenId, itemId)][buyerTokenId];

//     require(offerData != 0, hex'2E');

//     // if "isLeader"
//     if (uint160(offerData) == uint160(swapData)) {
//         // require "isOwner" or "isOver
//         require(swapData.epoch() == 0 || epoch() > swapData.epoch(), hex'67');

//         delete itemAgency[encItemId(sellerTokenId, itemId)];

//         assert(protocolItems[itemId] > 0);

//         addItem(buyerTokenId, itemId);

//         protocolItems[itemId]--;
//     } else {
//         assembly {
//             // extract "eth" from offerData object and decompress
//             value := mul(and(shr(offerData, 160), sub(shl(70, 1), 1)), LOSS)
//         }
//     }

//     emit ClaimItem(encItemId(sellerTokenId, itemId), buyerTokenId);
// }
// function claimItem(
//     uint160[] calldata buyerTokenIds,
//     uint160[] calldata sellerTokenIds,
//     uint16[] calldata itemIds
// ) external {
//     uint256 active = epoch();

//     assembly {
//         let ptr := mload(0x40)
//         let acc := 0

//         let len := calldataload(sub(buyerTokenIds.offset, 0x20))

//         if iszero(and(eq(len, calldataload(sub(sellerTokenIds.offset, 0x20))), eq(len, calldataload(sub(itemIds.offset, 0x20))))) {
//             // arrays are not the same length
//             mstore8(0x0, 0x99)
//             // calldatacopy(0x00, tokenIds.offset, 0x32)
//             revert(0x00, 0x01)
//         }

//         mstore(add(ptr, 0x20), itemAgency.slot)

//         mstore(add(ptr, 0x60), itemOffers.slot)

//         mstore(add(ptr, 0xa0), agency.slot)

//         for {
//             let i := 0
//             let buyerPtr := buyerTokenIds.offset
//             let sellerPtr := sellerTokenIds.offset
//             let itemPtr := itemIds.offset
//         } lt(i, len) {
//             i := add(i, 1)
//             buyerPtr := add(buyerPtr, 0x20)
//             sellerPtr := add(sellerPtr, 0x20)
//             itemPtr := add(itemPtr, 0x20)
//         } {
//             let buyer := calldataload(buyerPtr)
//             let sellerItem := or(shl(160, calldataload(itemPtr)), calldataload(sellerPtr))

//             mstore(ptr, sellerItem)
//             // let agency__slo := keccak256(ptr, 0x40)
//             let agency__cache := sload(keccak256(ptr, 0x40))

//             mstore(add(ptr, 0x40), sellerItem)
//             let offerSlot := keccak256(add(ptr, 0x40), 0x40)
//             mstore(add(ptr, 0x40), buyer)
//             mstore(add(ptr, 0x60), offerSlot)
//             offerSlot := keccak256(add(ptr, 0x40), 0x40)

//             mstore(add(ptr, 0x80), buyer)
//             let buyerOwner := shr(96, shl(96, sload(keccak256(add(ptr, 0x80), 0x40))))

//             switch eq(buyer, shr(96, shl(96, agency__cache)))
//             case 1 {
//                 let real := shr(232, shl(2, agency__cache))

//                 // require "isOwner" or "isOver"
//                 // == require(real == 0 || active > real)
//                 if and(iszero(iszero(real)), iszero(gt(active, real))) {
//                     mstore8(0x0, 0x67)
//                     revert(0x00, 0x01)
//                 }

//                 sstore(offerSlot, 0)

//                 sstore(keccak256(ptr, 0x40), or(buyer, shl(254, 0x3)))
//             }
//             default {
//                 let offer__cache := sload(offerSlot)

//                 if iszero(offer__cache) {
//                     mstore8(0x0, 0x2E)
//                     revert(0x00, 0x01)
//                 }

//                 // update state before we potentially send value
//                 sstore(offerSlot, 0)

//                 switch eq(caller(), buyerOwner)
//                 case 1 {
//                     acc := add(acc, shr(186, shl(26, offer__cache)))
//                 }
//                 default {
//                     // let real := shr(232, shl(2, offer__cache))

//                     // if swap is active, require the user is the caller
//                     if gt(active, shr(232, shl(2, offer__cache))) {
//                         if iszero(eq(caller(), buyerOwner)) {
//                             mstore8(0x0, 0x68)
//                             revert(0x00, 0x01)
//                         }
//                     }

//                     let amt := mul(shr(186, shl(26, offer__cache)), LOSS)

//                     if iszero(call(gas(), buyerOwner, amt, 0, 0, 0, 0)) {
//                         mstore8(0x0, 0x91)
//                         revert(0x00, 0x01)
//                     }
//                 }
//             }

//             log3(0x00, 0x00, CLAIMITEM, sellerItem, buyer)
//         }

//         if iszero(acc) {
//             return(0, 0)
//         }
//         if iszero(call(gas(), caller(), mul(acc, LOSS), 0, 0, 0, 0)) {
//             mstore8(0x0, 0x92)
//             revert(0x00, 0x01)
//         }
//     }
// }
