//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


library Structs0x {

    struct FillResults {
        uint256 makerAssetFilledAmount;  
        uint256 takerAssetFilledAmount;  
        uint256 makerFeePaid;            
        uint256 takerFeePaid;            
    }

    struct Order {
        address makerAddress;               
        address takerAddress;              
        address feeRecipientAddress;    
        address senderAddress;         
        uint256 makerAssetAmount;        
        uint256 takerAssetAmount;           
        uint256 makerFee;             
        uint256 takerFee;              
        uint256 expirationTimeSeconds;           
        uint256 salt;                   
        bytes makerAssetData;          
        bytes takerAssetData;       
    }

}