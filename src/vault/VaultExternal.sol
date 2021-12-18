// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {SafeCastLib} from '../libraries/SafeCastLib.sol';

import {IVaultExternal} from '../interfaces/INuggFT.sol';
import {IERC721Metadata} from '../interfaces/IERC721.sol';
import {IPostProcessResolver, IProcessResolver, IPreProcessResolver} from '../interfaces/IResolver.sol';

import {VaultCore} from './VaultCore.sol';
import {VaultView} from './VaultView.sol';

import {TokenView} from '../token/TokenView.sol';

import {EpochView} from '../epoch/EpochView.sol';

import {ProofView} from '../proof/ProofView.sol';

abstract contract VaultExternal is IVaultExternal {
    using SafeCastLib for uint256;

    address public immutable defaultResolver;

    constructor(address _dr) {
        defaultResolver = _dr;
    }

    function resolverOf(uint160 tokenId) public view virtual override returns (address) {
        return VaultView.resolverOf(tokenId);
    }

    function addToVault(uint256[][][] calldata data) external {
        VaultCore.set(data);
    }

    function rawProcessURI(uint160 tokenId) public view returns (uint256[] memory res) {
        require(TokenView.exists(tokenId) || tokenId == EpochView.activeEpoch(), 'NFT:NTM:0');

        (, uint16[] memory ids, , uint16[] memory overrides) = ProofView.parsedProofOfIncludingPending(tokenId);

        bytes memory data = abi.encode(tokenId, ids, overrides, address(this));

        uint256[][] memory files = VaultCore.getBatch(ids);

        res = IProcessResolver(defaultResolver).process(files, data, '');
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory res) {
        res = string(
            tokenURI(tokenId, VaultView.hasResolver(tokenId.safe160()) ? VaultView.resolverOf(tokenId.safe160()) : defaultResolver)
        );
    }

    function tokenURI(uint256 tokenId, address resolver) public view returns (bytes memory res) {
        require(ProofView.hasProof(tokenId.safe160()) || tokenId == EpochView.activeEpoch(), 'NFT:NTM:0');

        (, uint16[] memory ids, , uint16[] memory overrides) = ProofView.parsedProofOfIncludingPending(tokenId.safe160());

        uint256[][] memory files = VaultCore.getBatch(ids);

        bytes memory data = abi.encode(tokenId, ids, overrides, address(this));

        bytes memory customData = IPreProcessResolver(resolver).preProcess(data);

        uint256[] memory processedFile = IProcessResolver(resolver).process(files, data, customData);

        return IPostProcessResolver(resolver).postProcess(processedFile, data, customData);
    }
}