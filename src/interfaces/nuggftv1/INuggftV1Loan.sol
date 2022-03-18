// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.13;

interface INuggftV1Loan {
    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                EVENTS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/

    event Loan(uint160 indexed tokenId, bytes32 agency);

    event Rebalance(uint160 indexed tokenId, bytes32 agency);

    event Liquidate(uint160 indexed tokenId, bytes32 agency);

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            STATE CHANGING
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/

    function rebalance(uint160[] calldata tokenIds) external payable;

    function loan(uint160[] calldata tokenIds) external;

    function liquidate(uint160 tokenId) external payable;

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            VIEW FUNCTIONS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/

    /// @notice for a nugg's active loan: calculates the current min eth a user must send to liquidate or rebalance
    /// @dev contract     ->
    /// @param tokenId    -> the token who's current loan to check
    /// @return isLoaned  -> indicating if the token is loaned
    /// @return account   -> indicating if the token is loaned
    /// @return prin      -> the current amount loaned out, plus the final rebalance fee
    /// @return fee       -> the fee a user must pay to rebalance (and extend) the loan on their nugg
    /// @return earn      -> the amount of eth the minSharePrice has increased since loan was last rebalanced
    /// @return expire    -> the epoch the loan becomes insolvent
    function debt(uint160 tokenId)
        external
        view
        returns (
            bool isLoaned,
            address account,
            uint96 prin,
            uint96 fee,
            uint96 earn,
            uint24 expire
        );

    /// @notice "Values For Liquadation"
    /// @dev used to tell user how much eth to send for liquidate
    function vfl(uint160[] calldata tokenIds) external view returns (uint96[] memory vals);

    /// @notice "Values For Rebalance"
    /// @dev used to tell user how much eth to send for rebalance
    function vfr(uint160[] calldata tokenIds) external view returns (uint96[] memory vals);
}
