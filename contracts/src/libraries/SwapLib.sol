pragma solidity 0.8.4;
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import './ShiftLib.sol';
import './QuadMath.sol';

library SwapLib {
    using Address for address;
    using ShiftLib for uint256;

    struct Storage {
        uint256 data;
        mapping(uint256 => mapping(address => uint256)) offers;
    }

    function loadStorage(Storage storage s, address account)
        internal
        view
        returns (uint256 swapData, uint256 offerData)
    {
        swapData = s.data;

        offerData = swapData == 0 || account == swapData.account() ? swapData : s.offers[swapData.epoch()][account];
    }

    function loadStorage(
        Storage storage s,
        address account,
        uint256 epoch
    ) internal view returns (uint256 swapData, uint256 offerData) {
        swapData = s.data;

        swapData = swapData.epoch() == epoch ? swapData : 0;

        offerData = swapData != 0 && account == swapData.account() ? swapData : s.offers[epoch][account];
    }

    function checkClaimer(
        address account,
        uint256 swapData,
        uint256 offerData,
        uint256 activeEpoch
    ) internal pure returns (bool winner) {
        require(offerData != 0, 'SL:CC:1');

        bool over = activeEpoch > swapData.epoch();

        return swapData.isOwner() || (account == swapData.account() && over);
    }

    function points(uint256 total, uint256 bps) internal pure returns (uint256 res) {
        res = QuadMath.mulDiv(total, bps, 10000);
    }

    function pointsWith(uint256 total, uint256 bps) internal pure returns (uint256 res) {
        res = points(total, bps) + total;
    }

    function moveERC721(
        address token,
        uint256 tokenid,
        address from,
        address to
    ) internal {
        // require(IERC721(token).ownerOf(tokenid) == from, 'AUC:TT:1');

        IERC721(token).safeTransferFrom(from, to, tokenid);

        require(IERC721(token).ownerOf(tokenid) == to, 'AUC:TT:3');
    }

    function moveERC1155(
        address token,
        uint256 tokenid,
        uint256 itemid,
        bool from
    ) internal {
        // require(IERC721(token).ownerOf(tokenid) == from, 'AUC:TT:1');

        bytes memory data = abi.encode(itemid, tokenid, from);
        IERC1155(token).safeBatchTransferFrom(address(0), address(0), new uint256[](0), new uint256[](0), data);

        // require(moveERC1155(token).ownerOf(tokenid) == to, 'AUC:TT:3');
    }
}
