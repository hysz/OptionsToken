// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;


import "./libs/LibOption.sol";

import "./core/MixinState.sol";
import "./core/MixinToken.sol";

contract OptionToken is
    MixinState,
    /*
    MixinBalances,
    MixinAssets,
    MixinOptions,
    MixinTether,*/
    MixinToken/*,
    MixinERC721
    */
{

    constructor(address _priceOracle) public {
        priceOracle = IPriceOracle(_priceOracle);
        tokenIdNonce = 1;
    }


    ///// TOKEN API - Defined in ./core/MixinToken.sol /////

    function mint(LibOption.Option calldata option)
        external
        returns (bytes32 makerTokenId, bytes32 takerTokenId)
    {
        return _mint(msg.sender, option);
    }


    ///// OPTIONS API - Defined in ./core/MixinOptions.sol /////

/*
    function collateralize(
        bytes32 optionId,
        LibOption.Option calldata option,
        uint256 amount
    )
        external
    {
        _collateralize(optionId, option, amount);
    }

    function exercise(
        bytes32 optionId,
        LibOption.Option calldata option
    )
        external
    {
        _exercise(optionId, option);
    }
    
    function cancel(bytes32 optionId)
        external
    {
        _cancel(optionId);
    }

    */


/*
    ///// TETHERING API - Defined in ./core/MixinTether.sol /////

    function setCollateralizationTolerance(bytes32 optionId, uint256 tolerance)
        external
    {
        _setCollateralizationTolerance(optionId, tolerance);
    }

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
    
    function marginCall(LibOption.Option calldata option)
        external
    {
        _marginCall(option);
    }

    function canMarginCall(LibOption.Option calldata option)
        external
        returns (bool)
    {
        return _canMarginCall(option);
    }

    */
}