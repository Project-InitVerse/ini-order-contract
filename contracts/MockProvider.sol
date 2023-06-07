// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;
import "./ReentrancyGuard.sol";
import "hardhat/console.sol";
import "../interfaces/IProviderFactory.sol";
import "../interfaces/IOrderFactory.sol";

struct PriceOracle{
    address provider;
    uint256 cpu_price;
    uint256 memory_price;
    uint256 storage_price;
}
contract pro is IProvider{
    function consumeResource(uint256 ,uint256 ,uint256 ) external{

}
    function recoverResource(uint256, uint256, uint256) external{

    }
    function challenge() external view returns(bool){
        return false;
    }
    function owner() external view returns(address){
        return  address(1231);
    }
}
contract ProviderFactory is IProviderFactory{
    IProvider public ad;
    constructor(){
        ad = new pro();
    }
    // @notice Returns provider contract address if account is a provider else return 0x0
    function getProvideContract(address account) external override view returns(address){

        return address(ad);
    }

    // @notice Returns provider contract resources
    function getProvideResource(address account) external view override returns(uint256,uint256,uint256){
        return (10000000,1000000,100000);
    }

     function changeProviderResource(uint256 cpu_count, uint256 mem_count, uint256 storage_count, bool add) external override{

     }
    function consumeResource(address account,uint256 cpu_count, uint256 mem_count, uint256 storage_count) override external{

    }
    function recoverResource(address account,uint256 cpu_count, uint256 mem_count, uint256 storage_count) override external{

    }
    function getProvideTotalResource(address account) external override view returns(uint256,uint256,uint256){
        return (10000000,1000000,10000000);
    }
}
