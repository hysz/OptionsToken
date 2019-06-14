// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;


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
