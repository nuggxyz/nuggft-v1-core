// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import './libraries/SwapLib.sol';
import './interfaces/INuggSwap.sol';
// import './interfaces/IERC721Nuggable.sol';
import './libraries/CheapMath.sol';
import './libraries/ShiftLib.sol';

// import './interfaces/INuggSwapable.sol';
import './interfaces/IxNUGG.sol';

import './erc721/IERC721.sol';
import './core/Epochable.sol';
import './erc2981/IERC2981.sol';
import 'hardhat/console.sol';
import './common/Testable.sol';
import './erc721/ERC721Holder.sol';
import './erc1155/ERC1155Holder.sol';

// 80000000071158E460913D050272BE2A172EBEA775FD7ED68C32B0DC1032C55D
contract NuggSwap is INuggSwap, ERC721Holder, ERC1155Holder, Testable, Epochable {
    // event AddrLog(address msg_sender, address stored);
    using Address for address payable;
    using SwapLib for SwapLib.SwapData;
    using CheapMath for uint16;
    using ShiftLib for uint256;

    struct Storage {
        // uint256[] datas;
        mapping(uint256 => uint256) datas;
        mapping(address => mapping(uint256 => uint256)) users;
    }

    // mapping(address => uint256) internal _royalty;

    // mapping(address => uint256) _royalties;

    IxNUGG public immutable override xnugg;

    constructor(address _xnugg) Epochable(25, uint128(block.number)) {
        xnugg = IxNUGG(_xnugg);
    }

    function submitOffer(
        address token,
        uint256 tokenid,
        uint256 swapnum
    ) external payable override {
        _submitOffer(token, tokenid, swapnum, msg_sender(), msg_sender(), uint128(msg_value()));
    }

    function submitSwap(
        address token,
        uint256 tokenid,
        uint256 swapnum,
        uint48 requestedEpoch,
        uint128 requestedFloor,
        bool is1155
    ) external override {
        _submitSwap(token, tokenid, swapnum, msg_sender(), requestedEpoch, requestedFloor, is1155);
    }

    function submitClaim(
        address token,
        uint256 tokenid,
        uint256 swapnum
    ) external override {
        _submitClaim(token, tokenid, swapnum, msg_sender(), msg_sender());
    }

    function getSwap(
        address token,
        uint256 tokenid,
        uint256 swapnum
    ) external view override returns (SwapData memory res) {
        // var (, , , ) = loadStorage(token, tokenid, swapnum, address(0));
        // res.swapnum = _swapnum > numSwaps ? numSwaps : _swapnum;
        // res.amount = uint128(leaderData);
    }

    function _submitOffer(
        address token,
        uint256 tokenid,
        uint256 swapnum,
        address account,
        address to,
        uint256 value
    ) internal {
        (Storage storage s, uint256 swapData, uint256 offerData) = loadStorage(token, tokenid, swapnum, to);

        uint256 activeEpoch = currentEpochId();

        uint256 newSwapData;

        if (swapData != 0) {
            require(!offerData.offerIsOwner(), 'SL:HSO:0');
            // require(!offerData.isTokenClaimed(), 'SL:HSO:1');
            require(activeEpoch <= swapData.epoch() && !swapData.swapEndedByOwner(), 'SL:OBP:3');

            s.users[swapData.addr()][swapnum] = swapData;

            newSwapData = newSwapData.setEpoch(swapData.epoch());
            if (swapData.is1155()) newSwapData = newSwapData.setIs1155();
        } else if (swapnum == 0) {
            require(
                activeEpoch == tokenid.formattedTokenEpoch() && tokenid.formattedTokenAddress() == address(this),
                'SL:-1:0'
            );
            (uint256 epochInterval, bool is1155) = mintToken(token, tokenid);

            newSwapData = newSwapData.setEpoch(activeEpoch + epochInterval);

            if (is1155) newSwapData = newSwapData.setIs1155();
        } else {
            require(false, 'NS:SO:0');
        }

        newSwapData = newSwapData.setAccount(to);

        uint256 dust;
        (newSwapData, dust) = newSwapData.setEth(offerData.eth() + value);

        require(swapData.eth() < newSwapData.eth(), 'SL:OBP:4');
        s.datas[swapnum] = newSwapData;

        if (dust > 0) payable(account).sendValue(dust);

        emit SubmitOffer(token, tokenid, swapnum, to, value);
    }

    function _submitClaim(
        address token,
        uint256 tokenid,
        uint256 swapnum,
        address account,
        address to
    ) internal {
        (Storage storage s, uint256 swapData, uint256 offerData) = loadStorage(token, tokenid, swapnum, account);

        uint256 activeEpoch = currentEpochId();

        bool winner = SwapLib.checkClaimer(account, swapData, offerData, activeEpoch);

        if (winner) {
            SwapLib.moveERC721(token, tokenid, address(this), to);
            s.datas[swapnum] = swapData.setTokenClaimed();
        } else {
            // s.users[account][swapnum] = swapData.setTokenClaimed();
            delete s.users[account][swapnum];
            payable(to).sendValue(offerData.eth());
        }

        emit SubmitClaim(token, tokenid, swapnum, account);
    }

    function _submitSwap(
        address token,
        uint256 tokenid,
        uint256 swapnum,
        address account,
        uint48 requestedEpoch,
        uint256 requestedFloor,
        bool is1155 // uint16 tokenAmount, // uint8 tokenPrecision
    ) internal {
        require(swapnum > 0, 'NS:SS:-1');

        (Storage storage s, uint256 swapData, ) = loadStorage(token, tokenid, swapnum, account);

        require(swapData == 0, 'NS:SS:0');
        if (swapnum != 1) require(s.datas[swapnum - 1] != 0, 'NS:SS:1');

        uint256 epoch = currentEpochId() + requestedEpoch;

        (swapData, ) = uint256(uint160(account)).setEpoch(epoch).setFeeClaimed().setEth(requestedFloor);

        if (is1155) {
            SwapLib.moveERC1155(token, tokenid, account, address(this));
            swapData = swapData.setIs1155();
        } else SwapLib.moveERC721(token, tokenid, account, address(this));

        s.datas[swapnum] = swapData;

        emit SubmitSwap(token, tokenid, swapnum, account, requestedFloor, epoch);
    }

    function mintToken(address token, uint256 tokenid) internal view returns (uint256 epochInterval, bool is1155) {
        try IERC721(token).ownerOf(tokenid) returns (address addr) {
            require(addr == address(this), 'NS:MT:0');

            return (epochInterval, false);
        } catch {
            try IERC1155(token).balanceOf(address(this), tokenid) returns (uint256 amount) {
                require(amount > 0, 'NS:MT:1');
                return (0, true);
            } catch {
                require(false, 'NS:MT:0');
            }
        }
    }

    function loadStorage(
        address token,
        uint256 tokenid,
        uint256 swapnum,
        address account
    )
        internal
        view
        returns (
            Storage storage s,
            uint256 swapData,
            uint256 offerData
        )
    {
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x00), token)
            mstore(add(ptr, 0x20), tokenid)
            s.slot := keccak256(ptr, 52)
        }

        swapData = s.datas[swapnum];

        if (swapData == 0) {
            return (s, 0, 0);
        }

        if (account != address(uint160(swapData))) offerData = s.users[account][swapnum];
        else offerData = swapData;
    }
}
