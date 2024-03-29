// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "hardhat/console.sol";

import "../interfaces/ICert.sol";

    contract Cert is ICert{
        function user_cert_state(address user,string memory cert) external override view returns(CertState){
            return CertState.Using;
    }
        function getUserCert(address user,uint256 index)external view returns(certRetInfo memory){
            certRetInfo memory ret;
            ret.state = CertState.Using;
            return ret;
        }

}
