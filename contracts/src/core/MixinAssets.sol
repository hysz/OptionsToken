// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../libs/LibAsset.sol";
import "../interfaces/IERC20.sol";
import "./MixinState.sol";


contract MixinAssets is
    MixinState
{

    function _depositAsset(LibAsset.AssetType assetType, address from, uint256 amount) internal {
        IERC20 asset = assetType == LibAsset.AssetType.WETH ? wethToken : usdcToken;
        asset.transferFrom(from, address(this), amount);
    }

    function _withdrawAsset(LibAsset.AssetType assetType, address to, uint256 amount) internal {
        IERC20 asset = assetType == LibAsset.AssetType.WETH ? wethToken : usdcToken;
        asset.transfer(to, amount);
    }

    function _transferAsset(LibAsset.AssetType assetType, address from, address to, uint256 amount) internal {
        IERC20 asset = assetType == LibAsset.AssetType.WETH ? wethToken : usdcToken;
        asset.transferFrom(from, to, amount);
    }
}
