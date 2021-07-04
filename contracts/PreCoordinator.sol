//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;


import './interfaces/IPreCoordinator.sol';


contract PreCoordinator { 

    IPreCoordinator precoordinator = IPreCoordinator(0xf6c446Cb58735c52c35B0a22af13BDb39869D753);

    bytes32[] private jobIds = [
        bytes32('e67ddf1f394d44e79a9a2132efd00050'),
        bytes32('f2335e15bff140f4a26cee888c2ccfbf'),
        bytes32('a32d79b72f28437b8a30788ca62b0f21')
    ];


    address[] private oraclesAddr = [
        0x5b4247e58fe5a54A116e4A3BE32b31BE7030C8A3,
        0x688E8432e12620474d53b4A26Eb2E84eBEd4245c,
        0x2Ed7E9fCd3c0568dC6167F0b8aEe06A02CD9ebd8
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