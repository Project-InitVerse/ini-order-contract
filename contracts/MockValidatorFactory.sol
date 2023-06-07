// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IValidatorFactory.sol";

contract MockValidatorFactory is IValidatorFactory {
    constructor(){

    }
    function team_address() external view returns(address){
        return address(1234);
    }
}
