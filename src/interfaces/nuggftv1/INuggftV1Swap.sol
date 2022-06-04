// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

// prettier-ignore

interface INuggftV1Swap {
    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param tokenId (uint24)
    /// @param agency  (bytes32) a parameter just like in doxygen (must be followed by parameter name)
    event Offer(uint24 indexed tokenId, bytes32 agency, bytes32 stake);

    event OfferMint(uint24 indexed tokenId, bytes32 agency, bytes32 proof, bytes32 stake);

    event PreMint(uint24 indexed tokenId, bytes32 proof, bytes32 nuggAgency, uint16 indexed itemId, bytes32 itemAgency);

    event Claim(uint24 indexed tokenId, address indexed account);

    event Sell(uint24 indexed tokenId, bytes32 agency);




    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            STATE CHANGING
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    function offer(uint24 tokenId) external payable;

    function offer(
        uint24 tokenIdToClaim,
        uint24 nuggToBidOn,
        uint16 itemId,
        uint96 value1,
        uint96 value2
    ) external payable;

    function claim(
        uint24[] calldata tokenIds,
        address[] calldata accounts,
        uint24[] calldata buyingTokenIds,
        uint16[] calldata itemIds
    ) external;

    function sell(uint24 tokenId, uint96 floor) external;

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            VIEW FUNCTIONS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/

    /// @notice calculates the minimum eth that must be sent with a offer call
    /// @dev returns 0 if no offer can be made for this oken
    /// @param tokenId -> the token to be offerd to
    /// @param sender -> the address of the user who will be delegating
    /// @return canOffer -> instead of reverting this function will return false
    /// @return nextMinUserOffer -> the minimum value that must be sent with a offer call
    /// @return currentUserOffer ->
    function check(address sender, uint24 tokenId) external view
        returns (
            bool canOffer,
            uint96 nextMinUserOffer,
            uint96 currentUserOffer,
            uint96 currentLeaderOffer,
            uint96 incrementBps
        );

    function vfo(address sender, uint24 tokenId) external view returns (uint96 res);
}
