import './StorageLib.sol';
import './ShiftLib.sol';

library EpochLib {
    using ShiftLib for uint256;

    function activeEpoch() internal view returns (uint256 res) {
        res = toEpoch(block.number);
    }

    /**
     * @notice gets unique base based on given epoch and converts encoded bytes to object that can be merged
     * Note: by using the block hash no one knows what a nugg will look like before it's epoch.
     * We considered making this harder to manipulate, but we decided that if someone were able to
     * pull it off and make their own custom nugg, that would be really fucking cool.
     */
    function calculateSeed(uint256 blocknum) internal view returns (bytes32 res, uint256 epoch) {
        epoch = toEpoch(blocknum);
        uint256 startblock = toStartBlock(epoch);
        res = blockhash(startblock);
        if (startblock == blocknum) return (bytes32(uint256(0x42069)), 0);
        require(res != 0, 'EPC:SBL');
        res = keccak256(abi.encodePacked(res, epoch, address(this)));
    }

    function interval() internal pure returns (uint256 res) {
        res = 25;
    }

    function toStartBlock(uint256 epoch) internal pure returns (uint256 res) {
        res = epoch * interval();
    }

    function toEndBlock(uint256 epoch) internal pure returns (uint256 res) {
        res = toStartBlock(epoch + 1) - 1;
    }

    function toEpoch(uint256 blocknum) internal pure returns (uint256 res) {
        res = blocknum / interval();
    }
}
