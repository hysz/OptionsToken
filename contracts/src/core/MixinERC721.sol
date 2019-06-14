// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC721Receiver.sol";
import "../libs/LibToken.sol";
import "../libs/LibAddress.sol";
import "./MixinTokenMechanics.sol";


contract MixinERC721 is
    MixinTokenMechanics
{

    using LibAddress for address;

    bytes4 internal constant ERC721_ON_RECEIVED_CALLBACK = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return _getTokenOwner(bytes32(tokenId));
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        return _getTokenCount(owner);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 encodedTokenIds
    )
        internal
    {
        bytes32[] memory tokenIds = LibToken._decodeTokenIds(encodedTokenIds);
        for (uint256 i = 0; i != tokenIds.length; i++) {
            _transferToken(from, to, tokenIds[i]);
        }
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 encodedTokenIds
    )
        internal
    {

        // transfer token(s)
        _transferFrom(from, to, encodedTokenIds);

        // we're done if contract is not a receiver
        if (!to.isContract()) {
            return;
        }

        // `to` is a contract - execute its callback
        require(
            IERC721Receiver(to).onERC721Received(msg.sender, from, encodedTokenIds, bytes(hex"")) == ERC721_ON_RECEIVED_CALLBACK,
            "INVALID_ERC721_RECEIVER"
        );
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 encodedTokenIds,
        bytes memory
    )
        internal
    {
        _safeTransferFrom(from, to, encodedTokenIds);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        return _getTokenManager(bytes32(tokenId));
    }

    function _approve(address approved, uint256 tokenId) internal {
        _setTokenManager(bytes32(tokenId), approved);
    }

    function _setApprovalForAll(address operator, bool approved) internal {
        _setTokenOwnerOperator(msg.sender, operator, approved);
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return _isTokenOwnerOperator(owner, operator);
    }
}