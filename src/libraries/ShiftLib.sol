// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {SafeCastLib} from './SafeCastLib.sol';

library ShiftLib {
    using SafeCastLib for uint256;

    /// @notice creates a bit mask
    /// @dev res = (2 ^ bits) - 1
    /// @param bits d
    /// @return res d
    /// @dev no need to check if "bits" is < 256 as anything greater than 255 will be treated the same
    function mask(uint8 bits) internal pure returns (uint256 res) {
        assembly {
            res := sub(shl(bits, 1), 1)
        }
    }

    function fullsubmask(uint8 bits, uint8 pos) internal pure returns (uint256 res) {
        res = ~(mask(bits) << pos);
    }

    function set(
        uint256 preStore,
        uint8 bits,
        uint8 pos,
        uint256 value
    ) internal pure returns (uint256 postStore) {
        postStore = preStore & fullsubmask(bits, pos);

        assembly {
            value := shl(pos, value)
        }

        postStore |= value;
    }

    function get(
        uint256 store,
        uint8 bits,
        uint8 pos
    ) internal pure returns (uint256 value) {
        assembly {
            value := shr(pos, store)
        }
        value &= mask(bits);
    }

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                ARRAYS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/

    function getArray(uint256 store, uint8 pos) internal pure returns (uint8[] memory arr) {
        store = get(store, 64, pos);

        arr = new uint8[](8);
        for (uint256 i = 0; i < 8; i++) {
            arr[i] = uint8(store & 0xff);
            store >>= 8;
        }
    }

    function setArray(
        uint256 store,
        uint8 pos,
        uint8[] memory arr
    ) internal pure returns (uint256 res) {
        for (uint256 i = 8; i > 0; i--) {
            res |= uint256(arr[i - 1]) << ((8 * (i - 1)));
        }

        res = set(store, 64, pos, res);
    }

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            DYNAMIC ARRAYS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/

    // function setDynamicArray(
    //     uint256 store,
    //     uint16[] memory arr,
    //     uint8 bitsPerItem,
    //     uint8 pos,
    //     uint256 truelen,
    //     uint256 maxLen
    // ) internal view returns (uint256 res) {
    //     // must be different than popDynamicArray
    //     require(truelen <= maxLen, 'SL:SDA:0');

    //     res = set(store, 16, pos, (maxLen << 8) | truelen);

    //     res = setArray(res, arr, bitsPerItem, pos + 16);
    // }

    // function getDynamicArray(
    //     uint256 store,
    //     uint8 bitsPerItem,
    //     uint8 pos
    // )
    //     internal
    //     view
    //     returns (
    //         uint16[] memory arr,
    //         uint256 len,
    //         uint256 maxlen
    //     )
    // {
    //     len = get(store, 16, pos);

    //     maxlen = len >> 8;
    //     len &= 0xff;

    //     arr = getArray(store, bitsPerItem, pos + 16, len.safe8() + 1);
    // }

    // function popDynamicArray(
    //     uint256 store,
    //     uint8 bitsPerItem,
    //     uint8 pos,
    //     uint256 id
    // ) internal view returns (uint256 res) {
    //     (uint16[] memory arr, uint256 truelen, uint256 maxlen) = getDynamicArray(store, bitsPerItem, pos);

    //     require(truelen > 0, 'SL:PDA:0');

    //     bool found;
    //     for (uint8 i = 0; i < arr.length; i++) {
    //         if (arr[i] == id) found = true;

    //         if (found && i != arr.length - 1) arr[i] = arr[i + 1];
    //     }

    //     require(found, 'SL:PDA:0');

    //     res = setDynamicArray(store, arr, bitsPerItem, pos, truelen - 1, maxlen);
    // }

    // function pushDynamicArray(
    //     uint256 store,
    //     uint8 bitsPerItem,
    //     uint8 pos,
    //     uint16 id
    // ) internal view returns (uint256 res) {
    //     (uint16[] memory arr, uint256 truelen, uint256 maxlen) = getDynamicArray(store, bitsPerItem, pos);

    //     require(truelen < maxlen, 'SL:PDA:0');

    //     arr[truelen] = id;

    //     res = setDynamicArray(store, arr, bitsPerItem, pos, truelen + 1, maxlen);
    // }

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                             ASSERTIONS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/

    // function validateNum(uint256 num, uint8 bits) internal view {
    //     assert(num <= mask(bits));
    // }

    // function validateBits(uint8 bits) internal view {
    //     assert(bits <= 256);
    //     assert(bits > 0);
    // }

    // function validatePosWithLength(uint8 pos, uint256 length) internal view {
    //     // validateBits(length);
    //     assert(pos < 256 - length);
    //     assert(pos >= 0);
    // }

    // function validatePos(uint8 pos) internal view {
    //     assert(pos < 256);
    //     assert(pos >= 0);
    // }
}
