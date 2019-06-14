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

contract MixinTokenState is
    MixinState
{

    function _canSenderTransferToken(bytes32 tokenId, address sender) internal view returns (bool) {
        return _isTokenOwner(tokenId, sender) || _isTokenManager(tokenId, sender) || _isTokenOwnerOperator(_getTokenOwner(tokenId), sender);
    }

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

    function _assertTokenOwner(bytes32 tokenId, address owner) internal view {
        require(
            ownerByTokenId[tokenId] == owner,
            "OWNER_DOES_NOT_HOLD_TOKEN"
        );
    }

    function _assertHoldsBothTokens(bytes32 optionId, address owner) internal view {
        (bytes32 makerTokenId, bytes32 takerTokenId) = LibToken._getTokensFromOptionId(optionId);
        _assertTokenOwner(makerTokenId, owner);
        _assertTokenOwner(takerTokenId, owner);
    }
}
