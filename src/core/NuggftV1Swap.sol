// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {INuggftV1Swap} from '../interfaces/nuggftv1/INuggftV1Swap.sol';
import {NuggftV1Stake} from './NuggftV1Stake.sol';
import {SafeCastLib} from '../libraries/SafeCastLib.sol';
import {TransferLib} from '../libraries/TransferLib.sol';

import {NuggftV1AgentType} from '../types/NuggftV1AgentType.sol';
import '../_test/utils/forge.sol';

/// @notice mechanism for trading of nuggs between users (and items between nuggs)
/// @dev Explain to a developer any extra details
abstract contract NuggftV1Swap is INuggftV1Swap, NuggftV1Stake {
    using SafeCastLib for uint256;

    using NuggftV1AgentType for uint256;

    struct Mapping {
        Storage self;
        mapping(uint16 => Storage) items;
    }

    struct Storage {
        uint256 data;
        mapping(address => uint256) offers;
    }

    struct Memory {
        uint256 swapData;
        uint256 offerData;
        uint24 activeEpoch;
        address sender;
    }

    mapping(uint16 => uint256) protocolItems;
    mapping(uint160 => Mapping) swaps;

    uint96 public constant MIN_OFFER = 10 gwei;

    /// scenario
    /// stress
    // -- 8000 people offer

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                  offer
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    /// @inheritdoc INuggftV1Swap
    function offer(uint160 tokenId) external payable override {
        // console.log(tokenId);

        (Storage storage s, Memory memory m) = loadTokenSwap(tokenId, msg.sender);

        // make sure user is not the owner of swap
        // we do not know how much to give them when they call "claim" otherwise

        uint96 lead;
        // console.log(tokenId);

        if (m.activeEpoch == tokenId && m.swapData == 0) {
            // to ensure we at least have enough to increment the offer amount by 2%
            require(msg.value >= MIN_OFFER, hex'21');

            // we do not need this, could take tokenId out as an argument - but do not want to give users
            // the ability to accidently place an offer for nugg A and end up minting nugg B.
            assert(m.offerData == 0);
            // console.log(m.offerData);

            lead = msg.value.safe96();
            // console.log(lead);

            (s.data) = NuggftV1AgentType.newAgentType(m.activeEpoch, m.sender, lead, false);
            // console.log(s.data);
            addStakedShareFromMsgValue(0);
            // console.log(s.data);

            setProofFromEpoch(tokenId);

            emit Transfer(address(0), address(this), tokenId);
        } else {
            require(m.swapData != 0, hex'24');

            if (m.offerData != 0) {
                // forces user to claim previous swap before acting on this one
                // prevents owner from COMMITTING on their own swap - not offering
                require(m.offerData.epoch() >= m.activeEpoch, hex'20');

                assert(!m.offerData.flag()); // always be caught by the require above
            }

            // if the leader "owns" the swap, then it was initated by them - "commit" must be executed
            (lead) = m.swapData.flag() ? commit(s, m) : carry(s, m);
        }

        emit Offer(tokenId, msg.sender, lead);
    }

    /// @inheritdoc INuggftV1Swap
    function offerItem(
        uint160 buyerTokenId,
        uint160 sellerTokenId,
        uint16 itemId
    ) external payable override {
        require(_ownerOf(buyerTokenId) == msg.sender, hex'26');

        (Storage storage s, Memory memory m) = loadItemSwap(sellerTokenId, itemId, address(buyerTokenId));

        require(m.swapData != 0, hex'22');

        if (m.offerData != 0) {
            // forces user to claim previous swap before acting on this one
            // prevents owner from COMMITTING on their own swap - not offering
            require(m.offerData.epoch() >= m.activeEpoch, hex'27');

            assert(!m.offerData.flag()); // always be caught by the require above
        }

        uint96 lead = m.offerData == 0 && m.swapData.flag() ? commit(s, m) : carry(s, m);

        emit OfferItem(encodeSellingItemId(sellerTokenId, itemId), buyerTokenId, lead);
    }

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                  claim
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    /// @inheritdoc INuggftV1Swap
    function claim(uint160 tokenId) external override {
        TransferLib.sendEth(msg.sender, _claim(tokenId));
    }

    /// @inheritdoc INuggftV1Swap
    function multiclaim(uint160[] calldata tokenIds) external override {
        uint256 acc;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            acc += _claim(tokenIds[i]);
        }

        TransferLib.sendEth(msg.sender, acc);
    }

    function _claim(uint160 tokenId) internal returns (uint96 value) {
        (Storage storage s, Memory memory m) = loadTokenSwap(tokenId, msg.sender);

        delete s.offers[msg.sender];

        if (checkClaimerIsWinnerOrLoser(m)) {
            delete s.data;

            checkedTransferFromSelf(msg.sender, tokenId);
        } else {
            value = m.offerData.eth();
        }

        emit Claim(tokenId, msg.sender);
    }

    /// @inheritdoc INuggftV1Swap
    function claimItem(
        uint160 buyerTokenId,
        uint160 sellerTokenId,
        uint16 itemId
    ) public override {
        TransferLib.sendEth(msg.sender, _claimItem(buyerTokenId, sellerTokenId, itemId));
    }

    /// @inheritdoc INuggftV1Swap
    function multiclaimItem(
        uint160[] calldata buyerTokenIds,
        uint160[] calldata sellerTokenIds,
        uint16[] calldata itemIds
    ) external override {
        require(itemIds.length == sellerTokenIds.length && itemIds.length == buyerTokenIds.length, hex'23');

        uint96 value;

        for (uint256 i = 0; i < itemIds.length; i++) {
            value += _claimItem(buyerTokenIds[i], sellerTokenIds[i], itemIds[i]);
        }

        TransferLib.sendEth(msg.sender, value);
    }

    function _claimItem(
        uint160 buyerTokenId,
        uint160 sellerTokenId,
        uint16 itemId
    ) internal returns (uint96 value) {
        require(isAgent(msg.sender, buyerTokenId), hex'29');

        (Storage storage s, Memory memory m) = loadItemSwap(sellerTokenId, itemId, address(buyerTokenId));

        delete s.offers[address(buyerTokenId)];

        if (checkClaimerIsWinnerOrLoser(m)) {
            delete s.data;

            assert(protocolItems[itemId] > 0);

            addItem(buyerTokenId, itemId);

            protocolItems[itemId]--;
        } else {
            value = m.offerData.eth();
        }

        emit ClaimItem(encodeSellingItemId(sellerTokenId, itemId), buyerTokenId);
    }

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                  sell
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    /// @inheritdoc INuggftV1Swap
    function sell(uint160 tokenId, uint96 floor) external override {
        require(isOwner(msg.sender, tokenId), hex'2A');

        require(floor >= eps(), hex'2B');

        approvedTransferToSelf(tokenId);

        (Storage storage s, Memory memory m) = loadTokenSwap(tokenId, msg.sender);

        // make sure swap does not exist - this logically should never happen
        assert(m.swapData == 0);

        // no need to check dust as no value is being transfered
        (s.data) = NuggftV1AgentType.newAgentType(0, msg.sender, floor, true);

        emit Sell(tokenId, floor);
    }

    /// @inheritdoc INuggftV1Swap
    function sellItem(
        uint160 tokenId,
        uint16 itemId,
        uint96 floor
    ) external override {
        require(_ownerOf(tokenId) == msg.sender, hex'2C');

        // will revert if they do not have the item
        removeItem(tokenId, itemId);

        protocolItems[itemId]++;

        (Storage storage s, Memory memory m) = loadItemSwap(tokenId, itemId, address(tokenId));

        // cannot sell two of the same item at same time
        require(m.swapData == 0, hex'2D');

        (s.data) = NuggftV1AgentType.newAgentType(0, address(tokenId), floor, true);

        emit Sell(tokenId, floor);
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

        (, Memory memory m) = loadTokenSwap(tokenId, sender);

        if (m.swapData == 0) {
            if (m.activeEpoch == tokenId) {
                // swap is minting
                nextSwapAmount = NuggftV1AgentType.compressEthRoundUp(msp());

                // console.log(nextSwapAmount);
            } else {
                // swap does not exist
                return (false, 0, 0);
            }
        } else {
            if (m.offerData.flag() && m.swapData.flag()) canOffer = false;

            senderCurrentOffer = m.offerData.eth();

            nextSwapAmount = m.swapData.eth();

            if (nextSwapAmount < eps()) {
                nextSwapAmount = eps();
            }
        }

        if (nextSwapAmount == 0) {
            nextSwapAmount = MIN_OFFER;
        } else {
            nextSwapAmount = NuggftV1AgentType.addIncrement(nextSwapAmount);

            // console.log('2', nextSwapAmount);
        }
    }

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                internal
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    function commit(Storage storage s, Memory memory m) internal returns (uint96 lead) {
        require(msg.value >= eps(), hex'25');

        assert(m.offerData == 0 && m.swapData != 0);

        assert(m.swapData.flag());

        // forces a user not to commit on their own swap
        //commented out as the logic is handled by S:R
        // require(!m.offerData.flag()(), 0x23);

        uint24 newEpoch = m.activeEpoch + 1;

        (uint256 newSwapData, uint96 increment) = updateSwapDataWithEpoch(m.swapData, newEpoch, m.sender, 0);

        s.data = newSwapData;

        s.offers[m.swapData.account()] = m.swapData.flag(false).epoch(newEpoch);

        lead = newSwapData.eth();

        addStakedEth(increment);
    }

    function carry(Storage storage s, Memory memory m) internal returns (uint96 lead) {
        // make sure swap is still active
        require(m.activeEpoch <= m.swapData.epoch(), hex'2F');

        if (m.swapData.account() != m.sender) s.offers[m.swapData.account()] = m.swapData;

        (uint256 newSwapData, uint96 increment) = updateSwapDataWithEpoch(m.swapData, m.swapData.epoch(), m.sender, m.offerData.eth());

        s.data = newSwapData;

        lead = newSwapData.eth();

        addStakedEth(increment);
    }

    function checkClaimerIsWinnerOrLoser(Memory memory m) internal pure returns (bool winner) {
        require(m.offerData != 0, hex'2E');

        bool isOver = m.activeEpoch > m.swapData.epoch();
        bool isLeader = m.offerData.account() == m.swapData.account();
        bool flag = m.swapData.flag() && m.offerData.flag();

        return isLeader && (flag || isOver);
    }

    // @test  unit
    function updateSwapDataWithEpoch(
        uint256 prevSwapData,
        uint24 _epoch,
        address account,
        uint96 currUserOffer
    ) internal view returns (uint256 res, uint96 increment) {
        uint96 baseEth = prevSwapData.eth();

        currUserOffer += uint96(msg.value);

        require(NuggftV1AgentType.addIncrement(baseEth) <= currUserOffer, hex'26');

        (res) = NuggftV1AgentType.newAgentType(_epoch, account, currUserOffer, false);

        increment = currUserOffer - baseEth;
    }

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                TOKEN SWAP
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    function loadTokenSwap(uint160 tokenId, address account) internal view returns (Storage storage s, Memory memory m) {
        s = swaps[tokenId].self;
        m = _load(s, account);
    }

    function loadItemSwap(
        uint160 tokenId,
        uint16 itemId,
        address account
    ) internal view returns (Storage storage s, Memory memory m) {
        s = swaps[tokenId].items[itemId];
        m = _load(s, account);
    }

    function _load(Storage storage ptr, address account) private view returns (Memory memory m) {
        uint256 cache = ptr.data;
        m.swapData = cache;
        m.activeEpoch = epoch();
        m.sender = account;

        if (account == cache.account()) {
            m.offerData = cache;
        } else {
            m.offerData = ptr.offers[account];
        }
    }

    function encodeSellingItemId(uint160 tokenId, uint16 itemId) internal pure returns (uint176) {
        return (uint176(itemId) << 160) | tokenId;
    }
}
