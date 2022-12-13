// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "./ReentrancyGuard.sol";
import "./OrderBase.sol";
import "../interfaces/ICert.sol";


contract OrderFactory is IOrderFactory, ReentrancyGuard {
    // max order index start with 1
    uint256 private orderCount;
    // Mapping of order number to address
    mapping(uint256 => address) public orders;
    // Mapping of order address to number
    mapping(address => uint256) public order_base_map;
    // provider factory address
    address public provider_address;
    // Contract owner
    address public owner;
    // Minimum order deposit amount
    uint256 public minimum_deposit_amount;
    // Address of the certificate management center
    address public cert_center;
    // Contract creation event
    event OrderCreation(uint256 indexed orderNumber,address indexed owner,address indexed order_addr);

    // @dev Initialization parameters
    constructor() {
        orderCount=1;

        owner = msg.sender;

        minimum_deposit_amount = 5 ether;


    }
    // @dev only owner
    modifier only_owner() {
        require(msg.sender==owner, 'only owner');
        _;
    }


    // @dev Change the owner of the contract
    // @param Owner of the new contract
    function changeOwner(address new_owner) nonReentrant only_owner public{
        owner = new_owner;
    }

    // @dev Modify the provider factory address
    // @param new factory address
    function set_provider_factory(address factory_addr) only_owner nonReentrant public{
        provider_address = factory_addr;
    }
    // @dev Modify the cert center address
    // @param new cert center address
    function set_cert_center(address cert_center_) only_owner nonReentrant public{
        cert_center = cert_center_;
    }
    // @dev Create a new cloud server order
    // @param m_cpu  Number of resources requested by the cpu
    // @param m_memory  Number of resources requested by the memory
    // @param m_storage  Number of resources requested by the storage
    // @param m_cert  The server uses the certificate public key
    // @param m_trx_id Submit sdl's transaction hash
    function createOrder(uint256 m_cpu,uint256 m_memory,uint256 m_storage,string memory m_cert,string memory m_trx_id)  nonReentrant public returns(address){
        require(provider_address != address(0),"please wait admin set provider factory!");
        require(cert_center != address(0),"please wait admin set cert center!");
        require(ICert(cert_center).user_cert_state(msg.sender,m_cert) == CertState.Using);

        OrderBase base = new OrderBase(address(this),provider_address,msg.sender,m_cpu,m_memory,m_storage,m_cert,m_trx_id,orderCount);
        emit OrderCreation(orderCount,msg.sender,address(base));
        orders[orderCount]=address(base);
        order_base_map[address(base)]=orderCount;
        orderCount = orderCount+1;

        return address(base);
    }
    // @dev Obtain the order according to the order number
    function getOrder(uint256 orderId) external override view returns(Order memory) {
        require(orderId<orderCount,"order id not exists");
        return OrderBase(orders[orderId]).OrderInfo();
    }

    // @dev Check whether it is a legitimate order address
    function checkIsOrder(address orderAddress) external override view returns(uint256){
        uint256 orderNumber = order_base_map[orderAddress];
        return orderNumber;
    }

    // @dev Obtain all quotable orders
    function getUnCompleteOrder() public view returns(Order[] memory){

        uint256 tmp_count = 0;
        for(uint i = 1; i < orderCount; i++){

            Order memory tmp_order = OrderBase( orders[i]).OrderInfo();

            if( tmp_order.state==1){
                tmp_count=tmp_count+1;
            }
        }
        Order[] memory res = new Order[](tmp_count);
        uint256 index =0;
        for(uint i = 1; i < orderCount; i++){
            Order memory tmp_order = OrderBase( orders[i]).OrderInfo();
            if( tmp_order.state==1){

                Order memory m_order;
                m_order.owner=tmp_order.owner;
                m_order.v_cpu=tmp_order.v_cpu;
                m_order.v_memory=tmp_order.v_memory;
                m_order.v_storage=tmp_order.v_storage;
                m_order.cert_key=tmp_order.cert_key;
                m_order.trx_id=tmp_order.trx_id;
                m_order.state=tmp_order.state;
                res[index] = m_order;
                index = index+1;
            }
        }
        return res;
    }
    // @dev  Get the maximum order number
    function max_order_index()  external view returns(uint256){
        return orderCount -1;
    }
    // @dev Modify the minimum top-up amount
    function modify_minimum_deposit_amount(uint256 new_value) only_owner  external {
        minimum_deposit_amount = new_value;
    }
    // @dev get the minimum top-up amount
    function get_minimum_deposit_amount() external view override returns (uint256) {
        return minimum_deposit_amount;
    }


}
