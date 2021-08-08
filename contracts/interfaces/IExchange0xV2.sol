//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;


import '../libraries/Structs0x.sol';



interface IExchange0xV2  {
    

    // struct FillResults {
    //     uint256 makerAssetFilledAmount;  
    //     uint256 takerAssetFilledAmount;  
    //     uint256 makerFeePaid;            
    //     uint256 takerFeePaid;            
    // }

    // struct Order {
    //     address makerAddress;               
    //     address takerAddress;              
    //     address feeRecipientAddress;    
    //     address senderAddress;         
    //     uint256 makerAssetAmount;        
    //     uint256 takerAssetAmount;           
    //     uint256 makerFee;             
    //     uint256 takerFee;              
    //     uint256 expirationTimeSeconds;           
    //     uint256 salt;                   
    //     bytes makerAssetData;          
    //     bytes takerAssetData;       
    // }


    function fillOrder(
        Structs0x.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    ) external returns (Structs0x.FillResults memory fillResults);

    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        external
        view
        returns (bool isValid);

}