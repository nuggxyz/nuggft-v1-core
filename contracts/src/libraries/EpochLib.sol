import './ShiftLib.sol';

library EpochLib {
    using ShiftLib for uint256;

    // struct Storage {
    //     mapping(uint256 => uint256) seeds;
    // }

    // function setSeed(Storage storage s, uint256 genesis) internal returns (uint256 seed, uint256 epoch) {
    //     if (s.seeds[activeEpoch(genesis)] == 0) {
    //         (seed, epoch) = calculateSeed(genesis);
    //         s.seeds[epoch] = seed;
    //     }
    // }

    // /**
    //  * @dev #TODO
    //  * @return res
    //  */
    // function seedOf(Storage storage s, uint256 epoch) internal view returns (uint256 res) {
    //     res = s.seeds[epoch];
    // }

    // /**
    //  * @dev #TODO
    //  */
    // function safeSeedOf(
    //     Storage storage s,
    //     uint256 genesis,
    //     uint256 epoch
    // ) internal view returns (bool exists, uint256 seed) {
    //     seed = s.seeds[epoch];
    //     if (seed == 0 && activeEpoch(genesis) == epoch) {
    //         (seed, ) = calculateSeed(genesis);
    //     } else {
    //         exists = true;
    //     }
    // }

    /**
     * @dev #TODO
     * @return res
     */
    function activeEpoch(uint256 genesis) internal view returns (uint256 res) {
        res = toEpoch(genesis, block.number);
    }

    /**
     * @notice gets unique base based on given epoch and converts encoded bytes to object that can be merged
     * Note: by using the block hash no one knows what a nugg will look like before it's epoch.
     * We considered making this harder to manipulate, but we decided that if someone were able to
     * pull it off and make their own custom nugg, that would be really fucking cool.
     */
    function calculateSeed(uint256 genesis) internal view returns (uint256 res, uint256 epoch) {
        epoch = toEpoch(genesis, block.number);
        uint256 startblock = toStartBlock(genesis, epoch);
        bytes32 bhash = blockhash(startblock - 1);
        // if (startblock == block.number) return (uint256(uint256(0x42069)), 0);
        require(bhash != 0, 'EPC:SBL');
        res = uint256(keccak256(abi.encodePacked(bhash, epoch, address(this))));
        // res = uint256(b);
    }

    function interval() internal pure returns (uint256 res) {
        res = 25;
    }

    /**
     * @dev #TODO
     * @return res
     */
    function toStartBlock(uint256 genesis, uint256 epoch) internal pure returns (uint256 res) {
        res = (epoch * interval()) + genesis;
    }

    /**
     * @dev #TODO
     * @return res
     */
    function toEndBlock(uint256 genesis, uint256 epoch) internal pure returns (uint256 res) {
        res = toStartBlock(genesis, epoch + 1) - 1;
    }

    function toEpoch(uint256 genesis, uint256 blocknum) internal pure returns (uint256 res) {
        res = (blocknum - genesis) / interval();
    }
}
