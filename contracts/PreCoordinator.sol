//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;


import './interfaces/IPreCoordinator.sol';


contract PreCoordinator { 

    IPreCoordinator precoordinator = IPreCoordinator(0xf6c446Cb58735c52c35B0a22af13BDb39869D753);

    bytes32[] private jobIds = [
        bytes32('1bc4f827ff5942eaaa7540b7dd1e20b9'), 
        bytes32('e67ddf1f394d44e79a9a2132efd00050'), 
        bytes32('69384ee664624bbd8069a9be17416da2') 
    ];


    address[] private oraclesAddr = [
        0x240BaE5A27233Fd3aC5440B5a598467725F7D1cd, 
        0x5b4247e58fe5a54A116e4A3BE32b31BE7030C8A3, 
        0x9308B0Bd23794063423f484Cd21c59eD38898108 
    ];

    uint[] private payment = [
        1 * 10 ** 18,
        1 * 10 ** 18,
        1 * 10 ** 18
    ];

    function createServiceAgreement() external returns(bytes32) {
        return precoordinator.createServiceAgreement(2, oraclesAddr, jobIds, payment);
    }


}