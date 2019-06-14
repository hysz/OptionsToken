/**
 *Submitted for verification at Etherscan.io on 2017-05-10
*/

/// return median value of feeds

// Copyright (C) 2017  DappHub, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

library LibOption {
    enum OptionType {
        NIL,
        AMERICAN_CALL,
        AMERICAN_PUT,
        PUT
    }

    enum AssetType {
        NIL,
        WETH,
        USDC
    }
    
    struct Option {
        OptionType optionType;
        AssetType makerAsset;
        AssetType takerAsset;
        uint256 makerAmount;
        uint256 takerAmount;
        uint256 expirationTimeInSeconds;
    }

    struct OptionState {
        OPEN,
        CANCELLED,
        EXERCISED,
        EXPIRED
    }
    
    function getOptionHash(Option memory option) public pure returns (bytes32) {
        
    }
}

contract MarginContract {

    function 

}

contract MixinCore {

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



// Can create options for a ETH/USDC.
contract ClippyToken is MixinBalances {
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


interface IMedianizer {
    
    // deployed at  0x729D19f657BD0614b4985Cf1D82531c67569197B
    function compute() external pure returns (bytes32, bool);
}






contract MixinERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 optionHash
    )
        external
    {
        require(isCollateralized)
    }
}


contract MixinBalances {
    
    mapping (address => uint256) private ethBalanceByOwner;
    mapping (address => uint256) private usdcBalanceByOwner;
    
    function getEthBalance(address owner)
        public
        view
        returns (uint256)
    {
        return ethBalanceByOwner[owner];
    }
    
    function _depositEth(address owner, uint256 amount)
        internal
    {
        
    }
    
    function _withdrawEth(address owner, uint256 amount)
        internal
    {
        
    }
        
    function getUsdcBalance(address owner)
        public
        view
        returns (uint256)
    {
        return usdcBalanceByOwner[owner];
    }
    
    function _depositUsdc(address owner, uint256 amount)
        internal
    {
        
    }
    
    function _withdrawUsdc(address owner, uint256 amount)
        internal
    {
        
    }
}





contract TokenProxy {
    
    modifier onlyByClippy() {
        
        _;
    }
    
    function ()
        external
        onlyByClippy
    {
        
    }
}