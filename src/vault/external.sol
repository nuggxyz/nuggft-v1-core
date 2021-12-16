// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IVaultExternal} from '../interfaces/INuggFT.sol';

import {VaultLogic} from './logic.sol';

import {VaultView} from './view.sol';

abstract contract VaultExternal is IVaultExternal {
    function resolverOf(uint256 tokenId) public view virtual override returns (address) {
        return VaultView.resolverOf(tokenId);
    }

    function addToVault(uint256[][][] calldata data) external {
        VaultLogic.set(data);
    }

    function rawProcessURI(uint256 tokenId) public view returns (uint256[] memory res) {
        require(TokenView.exists(tokenId) || tokenId == EpochView.activeEpoch(), 'NFT:NTM:0');

        (, uint256[] memory ids, , uint256[] memory overrides) = ProofView.parsedProofOfIncludingPending(tokenId);

        bytes memory data = abi.encode(tokenId, ids, overrides, address(this));

        uint256[][] memory files = VaultLogic.getBatch(ids);

        res = IProcessResolver(defaultResolver).process(files, data, '');
    }

    function tokenURI(uint256 tokenId) public view override(IERC721Metadata, Tokenable) returns (string memory res) {
        res = string(tokenURI(tokenId, VaultView.hasResolver(tokenId) ? VaultView.resolverOf(tokenId) : defaultResolver));
    }

    function tokenURI(uint256 tokenId, address resolver) public view returns (bytes memory res) {
        require(Global.ptr().hasProof(tokenId) || tokenId == _genesis.activeEpoch(), 'NFT:NTM:0');

        (, uint256[] memory ids, , uint256[] memory overrides) = ProofView.parsedProofOfIncludingPending(tokenId);

        uint256[][] memory files = VaultLogic.getBatch(ids);

        bytes memory data = abi.encode(tokenId, ids, overrides, address(this));

        bytes memory customData = IPreProcessResolver(resolver).preProcess(data);

        uint256[] memory processedFile = IProcessResolver(resolver).process(files, data, customData);

        return IPostProcessResolver(resolver).postProcess(processedFile, data, customData);
    }
}
