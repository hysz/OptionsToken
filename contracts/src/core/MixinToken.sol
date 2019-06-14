// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

import "../libs/LibOption.sol";
import "../libs/LibToken.sol";

import "./MixinState.sol";


contract MixinToken is
    MixinState
{

    ///// TOKEN MECHANICS /////

    function _mintTokens(address owner, LibOption.Option memory option)
        internal
        returns (
            bytes32 makerTokenId,
            bytes32 takerTokenId
        )
    {
        // create tokens
        makerTokenId = bytes32(bytes16(tokenIdNonce)) << (2**128);
        takerTokenId = bytes32(bytes16(tokenIdNonce));
        tokenIdNonce += 1;

        // assign maker/taker token to owner
        _setTokenOwner(makerTokenId, owner);
        _setTokenOwner(takerTokenId, owner);

        // increment number of tokens held by owner
        tokenCountByOwner[owner] += 2;

        // assign option hash to tokens
        bytes32 optionId = makerTokenId | takerTokenId;
        bytes32 optionHash = LibOption.getOptionHash(option);
        optionHashById[optionId] = optionHash;

        return (makerTokenId, takerTokenId);
    }

    function _transferToken(
        address from,
        address to,
        bytes32 tokenId
    )
        internal
    {
        // sanity checks
        _assertTokenOwner(tokenId, from);
        _assertTokenIsTransferrable(tokenId);
        _assertCanSenderTransferToken(tokenId, msg.sender);

        // update token owner
        _setTokenOwner(tokenId, to);

        // update number of tokens held by owner
        tokenCountByOwner[from] -= 1;
        tokenCountByOwner[to] += 1;
    }

    function _isTokenTransferrable(bytes32 tokenId)
        internal
        view
        returns (bool isTransferrable)
    {
        /*
        bytes32 optionId = LibToken._getOptionIdFromTokenId(tokenId);
        isTransferrable = _getOptionState(optionId) == LibOption.OptionState.OPEN;
        return isTransferrable;
        */
    }

    function _canSenderTransferToken(bytes32 tokenId, address sender) internal view returns (bool) {
        return _isTokenOwner(tokenId, sender) || _isTokenManager(tokenId, sender) || _isTokenOwnerOperator(_getTokenOwner(tokenId), sender);
    }

    ///// CONVENIENCE FUNCTIONS FOR MANAGING & QUERYING STATE /////

    function _setTokenOwner(bytes32 tokenId, address owner)
        internal
    {
        ownerByTokenId[tokenId] = owner;
        _setTokenManager(tokenId, owner);
    }

    function _getTokenOwner(bytes32 tokenId)
        internal
        view
        returns (address)
    {
        return ownerByTokenId[tokenId];
    }

    function _isTokenOwner(bytes32 tokenId, address owner)
        internal
        view
        returns (bool)
    {
        return _getTokenOwner(tokenId) == owner;
    }

    function _getTokenCount(address owner) internal view returns (uint256) {
        return tokenCountByOwner[owner];
    }

    function _setTokenManager(bytes32 tokenId, address manager) internal {
        managerByTokenId[tokenId] = manager;
    }

    function _getTokenManager(bytes32 tokenId) internal view returns (address) {
        return managerByTokenId[tokenId];
    }

    function _isTokenManager(bytes32 tokenId, address manager) internal view returns (bool) {
        return (_getTokenManager(tokenId) == manager);
    }

    function _isTokenOwnerOperator(address owner, address operator) internal view returns (bool) {
        return tokenOwnerOperatorsByAddress[owner][operator];
    }

    function _setTokenOwnerOperator(address owner, address operator, bool isOwnerOperator) internal {
        tokenOwnerOperatorsByAddress[owner][operator] = isOwnerOperator;
    }

    ///// ASSERTIONS /////

    function _assertCanSenderTransferToken(bytes32 tokenId, address sender) internal view {
        require(
            _canSenderTransferToken(tokenId, sender),
            "SENDER_CANNOT_TRANSFER_TOKEN"
        );
    }

    function _assertTokenOwner(bytes32 tokenId, address owner) internal view {
        require(
            ownerByTokenId[tokenId] == owner,
            "OWNER_DOES_NOT_HOLD_TOKEN"
        );
    }

    function _assertTokenIsTransferrable(bytes32 tokenId) internal view {
        require(
            _isTokenTransferrable(tokenId),
            "ONLY_OPEN_OPTIONS_CAN_BE_TRANSFERRED"
        );
    }
}
