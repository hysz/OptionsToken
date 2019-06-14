// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;


contract MixinToken {

    mapping (bytes32 => address) ownerByTokenId;

    uint128 tokenIdNonce;

    mapping (bytes32 => bytes32) optionHashById;
    
    function _mintTokens(address owner, LibOption.Option memory option) internal returns (bytes32 makerTokenId, bytes32 takerTokenId) {
        // create tokens
        makerTokenId = tokenIdNonce << (2**128);
        takerTokenId = tokenIdNonce;
        tokenIdNonce += 1;

        // assign maker/taker token to owner
        ownerByTokenId[makerTokenId] = owner;
        ownerByTokenId[takerTokenId] = owner;

        // assign option hash to tokens
        bytes32 optionId = makerTokenId | takerTokenId;
        bytes32 optionHash = LibOption.getOptionHash(option);
        optionHashById[optionId] = optionHash;

        return (makerTokenId, takerTokenId);
    }

    function _getOwner(bytes32 tokenId) internal view returns (address) {
        return ownerByTokenId[tokenId];
    }


    bytes32 makerTokenMask = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
    bytes32 takerTokenMask = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    function _getTokensFromOptionId(bytes32 optionId) internal pure returns (bytes32 makerTokenId, bytes32 takerTokenId) {
        makerTokenId = optionId & makerTokenMask;
        takerTokenId = optionId & takerTokenMask;

        return (makerTokenId, takerTokenId);
    }

    function _getOptionIdFromTokenId(bytes32 tokenId)
        internal
        pure
        returns (bytes32 optionId)
    {

    }

    function _assertOptionOwner(bytes32 optionId, address owner) internal view {
        (bytes32 makerTokenId, bytes32 takerTokenId) = _getTokensFromOptionId(optionId);
        require(
            _getOwner(makerTokenId) == owner,
            "OWNER_DOES_NOT_HOLD_MAKER_TOKEN"
        );
        require(
            _getOwner(takerTokenId) == owner,
            "OWNER_DOES_NOT_HOLD_TAKER_TOKEN"
        );
    }

    function _assertTokenOwner(bytes32 tokenId, address owner) internal view {
        require(
            ownerByTokenId[tokenId] == owner,
            "OWNER_DOES_NOT_HOLD_TOKEN"
        );
    }

    function _setTokenOwner(bytes32 tokenId, address owner) internal {
        tokenOwnerById[tokenId] = owner;
    }

    function _assertOptionIdMatchesOption(optionId, option) internal pure {

    }

    function _getOptionState(bytes32 optionId) internal pure {
        return optionStateById[optionId];
    }

    function _assertTokenIsTransferrable(bytes32 tokenId) internal pure {
        bytes32 optionId = _getOptionIdFromTokenId(tokenId);

        require(
            _getOptionState(optionId) == LibOption.OptionState.OPEN,
            "ONLY_OPEN_OPTIONS_CAN_BE_TRANSFERRED"
        );
    }
}