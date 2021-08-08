// //SPDX-License-Identifier: Unlicense
// pragma solidity ^0.8.0;
// pragma abicoder v2;

// import './libraries/Structs0x.sol';
// import './libraries/Helpers.sol';
// import './interfaces/IExchange0xV2.sol';

// import "hardhat/console.sol";



// contract Relayer0x {

//     IExchange0xV2 exchange0xV2 = IExchange0xV2(0x080bf510FCbF18b91105470639e9561022937712);

//     string EIP191_HEADER = "\x19\x01";

//     bytes32 EIP712_ORDER_SCHEMA_HASH = keccak256(abi.encodePacked(
//         "Order(",
//         "address makerAddress,",
//         "address takerAddress,",
//         "address feeRecipientAddress,",
//         "address senderAddress,",
//         "uint256 makerAssetAmount,",
//         "uint256 takerAssetAmount,",
//         "uint256 makerFee,",
//         "uint256 takerFee,",
//         "uint256 expirationTimeSeconds,",
//         "uint256 salt,",
//         "bytes makerAssetData,",
//         "bytes takerAssetData",
//         ")"
//     ));

//     bytes32 EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
//         "EIP712Domain(",
//         "string name,",
//         "string version,",
//         "address verifyingContract",
//         ")"
//     ));

//     bytes32 EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(
//         EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
//         keccak256(bytes("0x Protocol")),
//         keccak256(bytes("2")),
//         bytes('0xb3c9669a5706477a2b237d98edb9b57678926f04')
//     ));

   

//     Structs0x.Order TUSDWETH_order = Structs0x.Order({
//             makerAddress: 0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9,               
//             takerAddress: address(this),              
//             feeRecipientAddress: 0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9,    
//             senderAddress: 0x0000000000000000000000000000000000000000,         
//             makerAssetAmount: 224817300000000000000,        
//             takerAssetAmount: 882693420471000000000000,           
//             makerFee: 0,             
//             takerFee: 0,              
//             expirationTimeSeconds: 1620982324,           
//             salt: 1620982124141785846,                   
//             makerAssetData: bytes('0xf47261b0000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'),          
//             takerAssetData: bytes('0xf47261b00000000000000000000000000000000000085d4780b73119b644ae5ecd22b376')
//         });

//     function execute2() private view returns(bytes32) {
//         bytes32 x = keccak256(abi.encodePacked(
//                 EIP712_ORDER_SCHEMA_HASH,
//                 TUSDWETH_order.makerAddress,
//                 TUSDWETH_order.takerAddress,
//                 TUSDWETH_order.feeRecipientAddress,
//                 TUSDWETH_order.senderAddress,
//                 TUSDWETH_order.makerAssetAmount,
//                 TUSDWETH_order.takerAssetAmount,
//                 TUSDWETH_order.makerFee,
//                 TUSDWETH_order.takerFee,
//                 TUSDWETH_order.expirationTimeSeconds,
//                 TUSDWETH_order.salt,
//                 keccak256(TUSDWETH_order.makerAssetData),
//                 keccak256(TUSDWETH_order.takerAssetData)
//             ));
//             return x;
//     }



//     function executeSwap() public view {

//         bytes32 x = execute2();



//         bytes32 orderHash = keccak256(abi.encodePacked(
//             EIP191_HEADER,
//             EIP712_DOMAIN_HASH,
//             x
//         ));

//         console.log('is valild signature: ', exchange0xV2.isValidSignature(orderHash, 0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9, bytes('0x1c822482f018fcea4b549c13f9cc9946967098189f5de8325b6413484b08ebf5694a32d92e764fb4319812c7242987d13cdb2d4448701e2b73f9c9fcfc34c6e79703')));


//     }


// }