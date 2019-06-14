// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


import "./libs/LibOption.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IOptionToken.sol";
import "./core/MixinState.sol";
import "./core/MixinOptionMechanics.sol";
import "./core/MixinTokenMechanics.sol";
import "./core/MixinERC721.sol";

contract OptionToken is
    IOptionToken,
    MixinState,
    MixinOptionMechanics,
    MixinTokenMechanics,
    MixinERC721
{

    constructor(
        address _priceOracle,
        address _wethToken,
        address _usdcToken
    )
        public
    {
        priceOracle = IPriceOracle(_priceOracle);
        wethToken = IERC20(_wethToken);
        usdcToken = IERC20(_usdcToken);
        tokenIdNonce = 1;

    }


    ///// OPTIONS API - Defined in ./core/MixinOptions.sol /////

    function tokenize(LibOption.Option calldata option)
        external
        returns (
            bytes32 optionId,
            bytes32 makerTokenId,
            bytes32 takerTokenId
        )
    {
        return _mint(option, msg.sender);
    }

    function cancelAndBurn(
        bytes32 optionId,
        LibOption.Option calldata option
    )
        external
    {
        _cancelOption(optionId, option);
        _burn(optionId);
    }

    function collateralize(
        bytes32 optionId,
        LibOption.Option calldata option,
        uint256 amount
    )
        external
    {
        _collateralizeOption(optionId, option, amount);
    }

    function exercise(
        bytes32 optionId,
        LibOption.Option calldata option
    )
        external
    {
        _exerciseOption(optionId, option);
    }

    function getTokenOwner(bytes32 tokenId) external view returns (address) {
        return _getTokenOwner(tokenId);
    }

    function isFullyCollateralized(bytes32 optionId, LibOption.Option calldata option)
        external
        view
        returns (bool)
    {
        return _isOptionFullyCollateralized(optionId, option);
    }

    function isOpen(bytes32 optionId, LibOption.Option calldata option)
        external
        view
        returns (bool)
    {
        return _isOptionOpen(optionId, option);
    }
    

    ///// MARGIN API - Defined in ./core/MixinMargin.sol /////

/*
    function setMarginTolerance(bytes32 nakedOptionId, uint8 tolerance)
        external
    {
        _setCollateralizationTolerance(optionId, tolerance);
    }

    function getMarginTolerance(bytes32 nakedOptionId)
        external
        returns (uint8)
    {

    }

    function marginCall(bytes32 nakedOptionId, LibOption.Option calldata option)
        external
    {

    }

    function canMarginCall(bytes32 optionId, LibOption.Option calldata option)
        external
        returns (bool)
    {
        return _canMarginCall(option);
    }



    ///// TETHERING API - Defined in ./core/MixinTether.sol /////

    function tether(bytes32 leftOptionId, bytes32 rightOptionId)
        external
    {
        _tether(leftOptionId, rightOptionId);
    }

    function untether(
        bytes32 leftOptionId,
        LibOption.Option calldata leftOption,
        bytes32 rightOptionId,
        LibOption.Option calldata rightOption
    )
        external
    {
        _untether(leftOptionId, leftOption, rightOptionId, rightOption);
    }

    function canUntether(
        bytes32 leftOptionId,
        LibOption.Option calldata leftOption,
        bytes32 rightOptionId,
        LibOption.Option calldata rightOption
    )
        external
        returns (bool)
    {
        //return _canUntether(leftOptionId, leftOption, rightOptionId, rightOption);
    }
    */

    
    ///// TOKEN API - Defined in ./core/MixinToken.sol /////

    

    ///// ERC721 API - Defined in ./core/ERC721.sol /////

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownerOf(tokenId);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balanceOf(owner);
    }

    function transferFrom(
        address from,
        address to,
        uint256 encodedTokenIds
    )
        external
    {
       _transferFrom(from, to, encodedTokenIds);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 encodedTokenIds
    )
        external
    {
        _safeTransferFrom(from, to, encodedTokenIds);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 encodedTokenIds,
        bytes calldata
    )
        external
    {
        _safeTransferFrom(from, to, encodedTokenIds);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return _getApproved(tokenId);
    }

    function approve(address approved, uint256 tokenId) external {
        _approve(approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _isApprovedForAll(owner, operator);
    }
}