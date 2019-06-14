// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;


contract OptionToken is MixinBalances {
    // ETH/USD Price Oracle
    IMedianizer priceOracle;



    mapping (bytes32 => bytes32) tetherByOptionId;
    function _assertOptionNotTethered(bytes32 optionId) {
        require(
            tetherByOptionId[optionId] == 0,
            "OPTION_IS_TETHERED"
        );
    }

    mapping (bytes32 => uint256) collateralizationToleranceByOptionId;
    

    
    mapping (bytes32 => uint256) collateralByOptionId;
    mapping (bytes32 => bool) isCancelledByOptionHash;
    mapping (bytes32 => address) takerByOptionHash;
    
    constructor(address _priceOracle) public {
        priceOracle = IMedianizer(_priceOracle);
        tokenIdNonce = 1;
    }

    // mints two tokens - a maker and a taker token
    // the sender holds both
    function mint(LibOption.Option calldata option)
        external
        returns (bytes32 makerTokenId, bytes32 takerTokenId)
    {
        return _mintTokens(msg.sender, option);
    }

    function setCollateralizationTolerance(bytes32 optionId, uint256 tolerance)
        external
    {
        _assertOptionOwner(optionId, msg.sender);
        _assertOptionNotTethered(optionId);
        collateralizationToleranceByOptionId[leftOptionId] = tolerance;
    }

    // when tethered the options cannot be exercised
    function tether(bytes32 leftOptionId, bytes32 rightOptionId)
        external
    {
        _assertOptionOwner(leftOptionId, msg.sender);
        _assertOptionOwner(rightOptionId, msg.sender);

        _assertOptionNotTethered(leftOptionId);
        _assertOptionNotTethered(rightOptionId);

        tetherByOptionId[leftOptionId] = rightOptionId;
        tetherByOptionId[rightOptionId] = leftOptionId;
    }

    // can untether in two cases:
    // 1. Both are fully collateralized
    // 2. The options are expired
    function untether(
        bytes32 leftOptionId,
        LibOption.Option calldata leftOption,
        bytes32 rightOptionId,
        LibOption.Option calldata rightOption
    )
        external
    {
        
    }
    

    function _computeAmountToBeFullyCollateralized(bytes32 optionId, LibOption.Option memory option)
        internal
        pure
    {
        return option.makerAmount - collateralByOptionId[optionId];
    }
    
    // Collateralize an option
    function collateralize(
        bytes32 optionId,
        LibOption.Option calldata option,
        uint256 amount
    )
        external
    {
        _assertOptionIdMatchesOption(optionId, option);
        uint256 maxAmountAllowed = _computeAmountToBeFullyCollateralized();
        uint256 amountToDeposit = amount <= maxAmountAllowed ? amount : maxAmountAllowed;
        _depositAsset(option.makerAsset, amountToDeposit, msg.sender);
    }

    function exercise(
        bytes32 optionId,
        LibOption.Option calldata option
    )
        external
    {
        _assertOptionIdMatchesOption(optionId, option);
        _assertOptionNotTethered(optionId);
        _assertOptionFullyCollateralized(optionId, option);
        bytes32 (makerTokenId, takerTokenId) = _getTokensFromOptionId(optionId);
        _assertTokenOwner(takerTokenId, msg.sender);
        _assertOptionIsOpen(optionId);

        // perform transfers
        transferFrom(ownerByTokenId[takerTokenId], ownerByTokenId[makerTokenId], option.takerAsset, option.takerAmount);
        transferTo(ownerByTokenId[takerTokenId], option.makerAsset, option.makerAmount);

        // update option state
        _setOptionStateToExercised(optionId);
    }
    
    function cancel(bytes32 optionId)
        external
    {
        _assertOptionOwner(optionId, msg.sender);
        transferTo(msg.sender, option.makerAsset, option.makerAmount);
        _setOptionStateToCancelled(optionId);
    }
    
    // Margin call an under-collateralized position (makerdao price oracle)
    function marginCall(LibOption.Option calldata option)
        external
    {
        
    }

    function canMarginCall(LibOption.Option calldata option)
        external
    {
        
    }

    function _decodeTokenIds(uint256 encodedTokenIds)
        internal
        returns (bytes32[] memory tokenIds)
    {
        bytes32 (makerTokenId, takerTokenId) = _getTokensFromOptionId(makerTokenId, takerTokenId);
        if (makerTokenId != 0 && takerTokenId != 0) {
            tokenIds = new bytes32[](2);
            tokenIds[0] = makerTokenId;
            tokenIds[1] = takerTokenId;
        } else if (makerTokenId != 0) {
            tokenIds = new bytes32[](1);
            tokenIds[0] = makerTokenId;
        } else if (takerTokenId != 0) {
            tokenIds = new bytes32[](1);
            tokenIds[0] = takerTokenId;
        }

        return tokenIds;
    )

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