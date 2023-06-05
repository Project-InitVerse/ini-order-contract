// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;


interface IProviderFactory{

    // @notice Returns provider contract address if account is a provider else return 0x0
    function getProvideContract(address account) external view returns(address);

    // @notice Returns provider contract resources
    function getProvideResource(address account) external view returns(uint256,uint256,uint256);

     function changeProviderResource(uint256 cpu_count, uint256 mem_count, uint256 storage_count, bool add) external;
    function consumeResource(address account,uint256 cpu_count, uint256 mem_count, uint256 storage_count)external;
    function recoverResource(address account,uint256 cpu_count, uint256 mem_count, uint256 storage_count)external;
    function getProvideTotalResource(address account) external view returns(uint256,uint256,uint256);
}

interface IProvider{
    function consumeResource(uint256 ,uint256 ,uint256 ) external;
    function recoverResource(uint256, uint256, uint256) external;
    function challenge() external view returns(bool);
    function owner() external view returns(address);
}
