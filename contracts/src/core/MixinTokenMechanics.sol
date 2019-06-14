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
import "./MixinTokenState.sol";
import "./MixinOptionState.sol";
import "./MixinAssets.sol";


contract MixinTokenMechanics is
    MixinState,
    MixinTokenState,
    MixinOptionState,
    MixinAssets
{

    function _mint(LibOption.Option memory option, address owner)
        internal
        returns (
            bytes32 optionId,
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
        optionId = LibToken._getOptionIdFromTokenIds(makerTokenId, takerTokenId);
        _assignOptionToId(optionId, option);

        return (optionId, makerTokenId, takerTokenId);
    }

    function _burn(bytes32 optionId)
        internal
    {
        // check that both sides of option are held by sender
        (bytes32 makerTokenId, bytes32 takerTokenId) = LibToken._getTokensFromOptionId(optionId);
        _assertTokenOwner(makerTokenId, msg.sender);
        _assertTokenOwner(takerTokenId, msg.sender);

        // burn tokens
        _setTokenOwner(makerTokenId, address(0));
        _setTokenOwner(takerTokenId, address(0));

        // decrement number of tokens held by owner
        tokenCountByOwner[msg.sender] -= 2;
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
        bytes32 optionId = LibToken._getOptionIdFromTokenId(tokenId);
        isTransferrable = _getOptionState(optionId) == LibOption.OptionState.OPEN;
        return isTransferrable;
    }

    function _assertCanSenderTransferToken(bytes32 tokenId, address sender) internal view {
        require(
            _canSenderTransferToken(tokenId, sender),
            "SENDER_CANNOT_TRANSFER_TOKEN"
        );
    }

    function _assertTokenIsTransferrable(bytes32 tokenId) internal view {
        require(
            _isTokenTransferrable(tokenId),
            "ONLY_OPEN_OPTIONS_CAN_BE_TRANSFERRED"
        );
    }
}
