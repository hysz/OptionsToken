// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

import "../interfaces/IPriceOracle.sol";
import "../libs/LibOption.sol";

contract MixinState
{

    // For querying ETH/USD price
    

    // Token
    uint128 tokenIdNonce;
    mapping (bytes32 => address) ownerByTokenId;
    mapping (address => uint256) tokenCountByOwner;

    // ERC721
    mapping (bytes32 => address) managerByTokenId;
    mapping (address => mapping (address => bool)) tokenOwnerOperatorsByAddress;


    mapping (bytes32 => LibOption.OptionState) optionStateById;

    mapping (bytes32 => bytes32) optionHashById;

    mapping (bytes32 => bytes32) tetherByOptionId;
    mapping (bytes32 => uint256) collateralizationToleranceByOptionId;
    
    IPriceOracle priceOracle;

    
    mapping (bytes32 => uint256) collateralByOptionId;
    mapping (bytes32 => bool) isCancelledByOptionHash;
    mapping (bytes32 => address) takerByOptionHash;
}