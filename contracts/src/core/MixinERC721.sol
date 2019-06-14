// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;


contract MixinERC721 {
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 encodedTokenIds
    )
        external
    {
        bytes32[] memory tokenIds = _decodeTokenIds(encodedTokenIds);
        for (uint256 i = 0; i != tokenIds.length; i++) {
            _assertTokenOwner(tokenIds[i], from);
            _assertTokenIsTransferrable(tokenIds[i]);
            _setTokenOwner(tokenIds[i], to);
        }
    }
    
}