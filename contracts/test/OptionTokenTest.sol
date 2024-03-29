// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../src/libs/LibOption.sol";
import "../src/libs/LibAsset.sol";
import "../src/interfaces/IOptionToken.sol";

import "./utils/ISettablePriceOracle.sol";
import "./utils/CounterParty.sol";
import "./utils/ITestERC20.sol";


contract OptionTokenTest {

    ISettablePriceOracle oracle;
    IOptionToken optionToken;
    ITestERC20 wethToken;
    ITestERC20 usdcToken;
    CounterParty counterParty;


    constructor(
        address _optionToken,
        address _oracle,
        address _wethToken,
        address _usdcToken
    )
        public
    {
        optionToken = IOptionToken(_optionToken);
        oracle = ISettablePriceOracle(_oracle);
        wethToken = ITestERC20(_wethToken);
        usdcToken = ITestERC20(_usdcToken);

        wethToken.init();
        usdcToken.init();

        wethToken.approve(address(optionToken), wethToken.totalSupply()/2);
        usdcToken.approve(address(optionToken), usdcToken.totalSupply()/2);
        counterParty = new CounterParty(address(optionToken), address(wethToken), address(usdcToken));
        wethToken.transfer(address(counterParty), wethToken.totalSupply()/2);
        usdcToken.transfer(address(counterParty), usdcToken.totalSupply()/2);
    }

    event E (
        bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId
    );

    function testMinting() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });
        
        {
            // tokenize it!
            (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);
            require(
                optionId == 0x0000000000000000000000000000000100000000000000000000000000000001,
                "BAD_OPTION_ID"
            );
            require(
                makerTokenId == 0x0000000000000000000000000000000100000000000000000000000000000000,
                "BAD_MAKER_ID"
            );
            require(
                takerTokenId == 0x0000000000000000000000000000000000000000000000000000000000000001,
                "BAD_TAKER_ID"
            );
            require(
                optionToken.getTokenOwner(makerTokenId) == address(this),
                "TAKER_TOKEN_BAD_OWNER"
            );
            require(
                optionToken.getTokenOwner(makerTokenId) == address(this),
                "TAKER_TOKEN_BAD_OWNER"
            );
        }

        {
            // tokenize it!
            (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);
            require(
                optionId == 0x0000000000000000000000000000000200000000000000000000000000000002,
                "BAD_OPTION_ID"
            );
            require(
                makerTokenId == 0x0000000000000000000000000000000200000000000000000000000000000000,
                "BAD_MAKER_ID"
            );
            require(
                takerTokenId == 0x0000000000000000000000000000000000000000000000000000000000000002,
                "BAD_TAKER_ID"
            );
            require(
                optionToken.ownerOf(uint256(makerTokenId)) == address(this),
                "TAKER_TOKEN_BAD_OWNER"
            );
            require(
                optionToken.ownerOf(uint256(makerTokenId)) == address(this),
                "TAKER_TOKEN_BAD_OWNER"
            );
        }
    }

    function testCollateralize() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // partially collateralize it
        optionToken.collateralize(optionId, option, option.makerAmount - 1);
        require(
            wethToken.balanceOf(address(optionToken)) == option.makerAmount - 1,
            "DID_NOT_DEPOSIT"
        );

        // check collateral state
        require(
            optionToken.isFullyCollateralized(optionId, option) == false,
            "OPTION_SHOULD_NOT_BE_FULLY_COLLATERALIZED"
        );

        // fully collateralize it
        optionToken.collateralize(optionId, option, 1);
        require(
            wethToken.balanceOf(address(optionToken)) == option.makerAmount,
            "DID_NOT_DEPOSIT"
        );

        // check collateral state
        require(
            optionToken.isFullyCollateralized(optionId, option),
            "OPTION_SHOULD_BE_FULLY_COLLATERALIZED"
        );
    }

    function testCancelAndBurn() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // get my balance
        uint256 initBalance = wethToken.balanceOf(address(this));

        // collateralize it
        optionToken.collateralize(optionId, option, option.makerAmount);

        // cancel it
        optionToken.cancelAndBurn(optionId, option);

        // check refund
        uint256 finalBalance = wethToken.balanceOf(address(this));
        require(
            finalBalance == initBalance,
            "DID_NOT_GET_REFUNDED"
        );

        // check cancelled
        require(
            optionToken.isOpen(optionId, option) == false,
            "OPTION_STILL_OPEN"
        );

        // check tokens burned
        require(
            optionToken.getTokenOwner(makerTokenId) == address(0),
            "MAKER_TOKEN_NOT_BURNED"
        );
        require(
            optionToken.getTokenOwner(takerTokenId) == address(0),
            "TAKER_TOKEN_NOT_BURNED"
        );
    }

    function testExerciseLongAmericanCall() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // collateralize it
        optionToken.collateralize(optionId, option, option.makerAmount);

        // give the taker token to our counterparty
        optionToken.transferFrom(
            address(this),
            address(counterParty),
            uint256(takerTokenId)
        );

        // get balances before exercise
        uint256 initMakerBalanceWeth = wethToken.balanceOf(address(this));
        uint256 initMakerBalanceUsdc = usdcToken.balanceOf(address(this));
        uint256 initTakerBalanceWeth = wethToken.balanceOf(address(counterParty));
        uint256 initTakerBalanceUsdc = usdcToken.balanceOf(address(counterParty));

        // exercise the option
        counterParty.exercise(optionId, option);

        // get balacnes after exercise
        uint256 finalMakerBalanceWeth = wethToken.balanceOf(address(this));
        uint256 finalMakerBalanceUsdc = usdcToken.balanceOf(address(this));
        uint256 finalTakerBalanceWeth = wethToken.balanceOf(address(counterParty));
        uint256 finalTakerBalanceUsdc = usdcToken.balanceOf(address(counterParty));
        
        // check that funds were swapped
        require(
            finalMakerBalanceWeth - initMakerBalanceWeth == 0, // maker had already collateralized 
            "UNEXPECTED_MAKER_WETH_BALANCE"
        );
        require(
            finalMakerBalanceUsdc - initMakerBalanceUsdc == option.takerAmount,
            "UNEXPECTED_MAKER_USDC_BALANCE"
        );
        require(
            finalTakerBalanceWeth - initTakerBalanceWeth == option.makerAmount,
            "UNEXPECTED_TAKER_WETH_BALANCE"
        );
        require(
            initTakerBalanceUsdc - finalTakerBalanceUsdc == option.takerAmount,
            "UNEXPECTED_TAKER_USDC_BALANCE"
        );

        // check that option is now closed
        require(
            optionToken.isOpen(optionId, option) == false,
            "OPTION_SHOULD_BE_CLOSED"
        );
   }

    function testExerciseByNotOwner() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // collateralize it
        optionToken.collateralize(optionId, option, option.makerAmount);

        // try to exercise when counterparty does not hold option
        counterParty.exercise(optionId, option);
    }

    function testExerciseAfterExpiry() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp - 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // try to exercise when counterparty does not hold option
        optionToken.exercise(optionId, option);
    }

    function testExerciseTwice() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // collateralize it
        optionToken.collateralize(optionId, option, option.makerAmount);

        // try to exercise when counterparty does not hold option
        optionToken.exercise(optionId, option);

        // try to exercise when counterparty does not hold option
        optionToken.exercise(optionId, option);
    }

    function testExerciseWithInsufficientCollateral() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId,,) = optionToken.tokenize(option);

        // try to exercise when counterparty does not hold option
        optionToken.exercise(optionId, option);
    }

    function testSuccessfulMarginCall() external {
        // create an option
        LibOption.Option memory nakedOption = LibOption.Option({
            optionType: LibOption.OptionType.EUROPEAN_PUT,
            makerAsset: LibAsset.AssetType.USDC,
            takerAsset: LibAsset.AssetType.WETH,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(nakedOption);

        // set the margin tolerance to be 10%
        optionToken.setMarginTolerance(optionId, 10);

        // give the taker token to our counterparty
        optionToken.transferFrom(
            address(this),
            address(counterParty),
            uint256(takerTokenId)
        );

        // set the price to below the strike price
        oracle.setPrice(LibAsset._toBaseUnit(199));
        require(
            optionToken.canMarginCall(optionId, nakedOption),
            "SHOULD_HAVE_BEEN_ABLE_TO_MARGIN_CALL"
        );

        // collateralize with $1 to get outside of margin zone
        optionToken.collateralize(optionId, nakedOption, LibAsset._toBaseUnit(1));
        require(
            !optionToken.canMarginCall(optionId, nakedOption),
            "SHOULD_NOT_BE_ABLE_TO_MARGIN_CALL"
        );

        // set the price lower so that we can margin call again
        oracle.setPrice(LibAsset._toBaseUnit(198));


        // get balances before exercise
        uint256 initMakerBalanceWeth = wethToken.balanceOf(address(this));
        uint256 initMakerBalanceUsdc = usdcToken.balanceOf(address(this));
        uint256 initTakerBalanceWeth = wethToken.balanceOf(address(counterParty));
        uint256 initTakerBalanceUsdc = usdcToken.balanceOf(address(counterParty));

        // execute margin call
        optionToken.marginCall(optionId, nakedOption);

        // get balances after exercise
        uint256 finalMakerBalanceWeth = wethToken.balanceOf(address(this));
        uint256 finalMakerBalanceUsdc = usdcToken.balanceOf(address(this));
        uint256 finalTakerBalanceWeth = wethToken.balanceOf(address(counterParty));
        uint256 finalTakerBalanceUsdc = usdcToken.balanceOf(address(counterParty));

         // check that funds were swapped correctly
        require(
            finalMakerBalanceWeth - initMakerBalanceWeth == 0,
            "UNEXPECTED_MAKER_WETH_BALANCE"
        );
        require(
            finalMakerBalanceUsdc - initMakerBalanceUsdc == 0, // only his collateral was lost
            "UNEXPECTED_MAKER_USDC_BALANCE"
        );
        require(
            finalTakerBalanceWeth - initTakerBalanceWeth == 0,
            "UNEXPECTED_TAKER_WETH_BALANCE"
        );
        require(
             finalTakerBalanceUsdc - initTakerBalanceUsdc == LibAsset._toBaseUnit(1), // the collateral gained by taker
            "UNEXPECTED_TAKER_USDC_BALANCE"
        );

        // verify that option is closed
        require(
            !optionToken.isOpen(optionId, nakedOption),
            "OPTION_SHOULD_BE_CLOSED"
        );
    }

    function testUnsuccessfulMarginCall() external {
        // create an option
        LibOption.Option memory nakedOption = LibOption.Option({
            optionType: LibOption.OptionType.EUROPEAN_PUT,
            makerAsset: LibAsset.AssetType.USDC,
            takerAsset: LibAsset.AssetType.WETH,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(nakedOption);

        // set the margin tolerance to be 10%
        optionToken.setMarginTolerance(optionId, 10);

        // give the taker token to our counterparty
        optionToken.transferFrom(
            address(this),
            address(counterParty),
            uint256(takerTokenId)
        );

        // set the price to below the strike price
        oracle.setPrice(LibAsset._toBaseUnit(201));
        optionToken.marginCall(optionId, nakedOption);
    }

    function testSyntheticLong() external {
        // record initial balances
        uint256 initMakerBalanceWeth = wethToken.balanceOf(address(this));
        uint256 initMakerBalanceUsdc = usdcToken.balanceOf(address(this));
        uint256 initTakerBalanceWeth = wethToken.balanceOf(address(counterParty));
        uint256 initTakerBalanceUsdc = usdcToken.balanceOf(address(counterParty));

        // create a naked put option
        LibOption.Option memory callOption = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(1),
            takerAmount: LibAsset._toBaseUnit(200),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // create a naked put option
        LibOption.Option memory putOption = LibOption.Option({
            optionType: LibOption.OptionType.EUROPEAN_PUT,
            makerAsset: LibAsset.AssetType.USDC,
            takerAsset: LibAsset.AssetType.WETH,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize 'em!
        (bytes32 callOptionId,, bytes32 callTakerTokenId) = optionToken.tokenize(callOption);
        (bytes32 putOptionId, bytes32 putMakerTokenId,) = optionToken.tokenize(putOption);

        // collateralize the call
        optionToken.collateralize(callOptionId, callOption, callOption.makerAmount);

        // tether options
        optionToken.tether(callOptionId, callOption, putOptionId, putOption);

        // give the taker token to our counterparty
        optionToken.transferFrom(
            address(this),
            address(counterParty),
            uint256(callTakerTokenId | putMakerTokenId)
        );
        require(
            optionToken.getTokenOwner(callTakerTokenId) == address(counterParty),
            "CALL_TAKER_TOKEN_NOT_OWNED_BY_COUNTERPARTY"
        );
        require(
            optionToken.getTokenOwner(putMakerTokenId) == address(counterParty),
            "PUT_MAKER_TOKEN_NOT_OWNED_BY_COUNTERPARTY"
        );

        // Let's pump that price to entice the taker to byte!
        oracle.setPrice(500);

        // Counterparty now wishes to cash out; they initiate by fully collateralizing the put option.
        counterParty.collateralize(putOptionId, putOption, putOption.makerAmount);
     
        // Now both options are collateralized and can be untethered
        optionToken.untether(callOptionId, callOption, putOptionId, putOption);

        // the counterparty can now exercise the call option for the epic gains
        counterParty.exercise(callOptionId, callOption);

        // The issuer (me) can now choose to fill the put option or re-sell their position to someone else
        // Let's suppose they don't mind about the ETH price and just want to even out their balances, so they exercise.
        optionToken.exercise(putOptionId, putOption);

         // both options should be closed
        require(
            !optionToken.isOpen(putOptionId, putOption),
            "CALL_OPTION_SHOULD_BE_CLOSED"
        );
        require(
            !optionToken.isOpen(callOptionId, callOption),
            "PUT_OPTION_SHOULD_BE_CLOSED"
        );

        // get final balances
        uint256 finalMakerBalanceWeth = wethToken.balanceOf(address(this));
        uint256 finalMakerBalanceUsdc = usdcToken.balanceOf(address(this));
        uint256 finalTakerBalanceWeth = wethToken.balanceOf(address(counterParty));
        uint256 finalTakerBalanceUsdc = usdcToken.balanceOf(address(counterParty));

        // check balances
        // the maker earned no profit
        require(
            initMakerBalanceWeth - finalMakerBalanceWeth ==  LibAsset._toBaseUnit(2), // I'm down 2 ETH
            "UNEXPECTED_MAKER_WETH_BALANCE"
        );
        require(
            finalMakerBalanceUsdc - initMakerBalanceUsdc == LibAsset._toBaseUnit(400), // I'm up 2x the initial strike price
            "UNEXPECTED_MAKER_USDC_BALANCE"
        );
        // the taker now has 2 ETH valued much higher
        require(
            finalTakerBalanceWeth - initTakerBalanceWeth == LibAsset._toBaseUnit(2),
            "UNEXPECTED_TAKER_WETH_BALANCE"
        );
        require(
             initTakerBalanceUsdc - finalTakerBalanceUsdc  == LibAsset._toBaseUnit(400), // counterparty is down 2x the strike price
            "UNEXPECTED_TAKER_USDC_BALANCE"
        );
    }
}