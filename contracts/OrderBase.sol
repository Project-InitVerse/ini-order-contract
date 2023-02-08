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
    enum OrderStatus {
        Created,Quoting,Running,Ended
    }

contract OrderBase is ReentrancyGuard{
    // All Quotations of provider
    PriceOracle[] public provide_quotes;
    // Owner of order
    address public owner;
    // cpu Usage
    uint256 public o_cpu;
    // memory Usage
    uint256 public o_memory;
    // storage Usage
    uint256 public o_storage;
    // Order No.
    uint256 public o_order_number;
    // Order certificate key
    uint256 public o_cert;
    // Order submit sdl transaction hash
    uint256 public o_sdl_trx_id;
    // for Order update
    uint256 public o_pending_sdl_trx_id;
    // @notice 0 created 1 can quote 2 running 3 end order
    OrderStatus public order_status;

    // order factory address
    IOrderFactory order_factory;
    // provider factory address
    IProviderFactory public provider_factory;
    // Order selection quotation after aggregation calculated price
    uint256 public final_price ;
    // Final selection of quotation number
    uint256 public final_choice;
    // Time of last payment
    uint256 public last_pay_time;
    string public server_uri;
    uint256 public totalSpent;
    


    event OrderCreate(address owner_,uint256 cpu,uint256 memory_,uint256 storage_,uint256 cert,uint256 sdl,uint256 order_number);
    event Quote(address  provider,uint256  cpu_price,uint256  memory_price,uint256  storage_price);
    event ChooseQuote(address indexed provider,uint256 indexed final_price);
    event DepositBalance(uint256 indexed amount);
    event PayBill(address indexed provider, uint256 indexed amount);
    event OrderEnded();
    event UserCancelOrder();
    event UpdateSDL(uint256 new_sdl_trx_id);
    event DeployMentUpdated(uint256 old_cpu,uint256 old_memory,uint256 old_storage,uint256 new_cpu,uint256 new_memory,uint256 new_storage);
    event CanQuote();
    constructor(address _order_factory,address provider_factory_,address owner_,uint256 cpu_,uint256 memory_,uint256 storage_,uint256 cert_key_,uint256 sdl_trx_id_, uint256 order_number){
        owner =owner_;
        o_cpu=cpu_;
        o_memory =memory_;
        o_storage = storage_;
        o_order_number = order_number;
        provider_factory=IProviderFactory(provider_factory_);
        order_factory = IOrderFactory( _order_factory);
        order_status=OrderStatus.Created;
        last_pay_time = block.timestamp;
        o_sdl_trx_id = sdl_trx_id_;
        o_cert = cert_key_;
        o_pending_sdl_trx_id= uint256(0);
        totalSpent=uint256(0);
        emit OrderCreate(owner_,cpu_,memory_,storage_,cert_key_,sdl_trx_id_,order_number);
    }

    // @dev Only owner calls are allowed
    modifier only_owner() {
        require(msg.sender==owner, 'only owner');
        _;
    }
    // @dev Only the quote phase calls are allowed
    modifier only_quote_period() {
        require(order_status==OrderStatus.Quoting, 'only quote period can commit submission of quotation!');
        _;
    }
    
    // @dev Only the payment phase is called
    modifier only_pay_period() {
        require(order_status==OrderStatus.Created|| order_status==OrderStatus.Running, 'only inital period or running period can deposit balance!');
        _;
    }

    // @dev Only the provider can call
    modifier only_provider(){
        require(order_status==OrderStatus.Running);
        PriceOracle memory quote_data = provide_quotes[final_choice];
        //todo just for test.
        require(msg.sender == IProvider( quote_data.provider).owner());
        _;
    }
    // @dev provider quote interface
    // @param p_cpu cpu quote Amount
    // @param p_memory memory quote Amount
    // @param p_storage storage quote Amount
    function quote(uint256 p_cpu,uint256 p_memory,uint256 p_storage) only_quote_period nonReentrant public returns (uint256){
        address provider = provider_factory.getProvideContract(msg.sender);
        require(provider!=address(0),"only provider can quote");
        (uint256 r_cpu,uint256 r_memory,uint256 r_storage) = provider_factory.getProvideResource(provider);
        require(r_cpu>=o_cpu&&r_memory>=o_memory&&r_storage>=o_memory,"Insufficient resource balance");
        provide_quotes.push(PriceOracle(provider,p_cpu,p_memory,p_storage));
        emit Quote(provider,p_cpu,p_memory,p_storage);
        return provide_quotes.length -1;
    }

    // @dev Select provider quotation
    function query_provide_quotes() view public returns(PriceOracle[] memory){
        return provide_quotes;
    }

    // @dev Select provider quotation
    // @param provider quote select serial number
    function choose_provider(uint256 quote_index) only_owner only_quote_period nonReentrant public {
        require(quote_index< provide_quotes.length,"invaild index");
        PriceOracle memory quote_detail  = provide_quotes[quote_index];
        provider_factory.consumeResource(quote_detail.provider,o_cpu, o_memory, o_storage);
        order_status = OrderStatus.Running;
        final_choice = quote_index;
        final_price = quote_detail.cpu_price *o_cpu+quote_detail.memory_price*o_memory+quote_detail.storage_price*o_storage;
        last_pay_time = block.timestamp;
        emit ChooseQuote(quote_detail.provider,final_price);

    }
    // @dev Deposit for balance
    function deposit_balance() only_owner payable public {
        require(msg.value >= order_factory.get_minimum_deposit_amount(),"The minimum top-up amount limit is not met");
        if (order_status ==OrderStatus.Created){
            order_status =OrderStatus.Quoting;
            emit CanQuote();
        }
        emit DepositBalance(msg.value);

    }
    // @dev Modify the sdl submit transaction hash
    function change_sdl_trx_hash(uint256 new_trx_hash) only_owner public{
        require(order_status != OrderStatus.Running && order_status != OrderStatus.Created,"Only the creation and running states can modify the sdl");
        require(o_pending_sdl_trx_id==uint256(0),"There are update orders in process");
        if(order_status == OrderStatus.Running){
            o_pending_sdl_trx_id = new_trx_hash;
            emit UpdateSDL(new_trx_hash);
        }
        if(order_status == OrderStatus.Created){
            o_sdl_trx_id = new_trx_hash;
        }

    }

    // @dev Provider update order status
    function update_deployment(uint256 cpu_,uint256 memory_,uint256 storage_,string memory uri_) only_provider nonReentrant public{
        require(o_pending_sdl_trx_id != uint256(0),"There needs to be an update order task");
        _pay_billing(payable(msg.sender));
        // sub resource
        PriceOracle memory quote_detail  = provide_quotes[final_choice];
        provider_factory.recoverResource(quote_detail.provider,o_cpu, o_memory, o_storage);

        final_price = quote_detail.cpu_price *o_cpu+quote_detail.memory_price*memory_+quote_detail.storage_price*storage_;


        // add resource
        provider_factory.consumeResource(quote_detail.provider,cpu_, memory_, storage_);
        // cal new final_price
        emit DeployMentUpdated(o_cpu,o_memory,o_storage,cpu_,memory_,storage_);
        o_cpu = cpu_;
        o_memory = memory_;
        o_storage = storage_;
        server_uri=uri_;
        o_pending_sdl_trx_id= uint256(0);
    }


    // @dev Obtain basic order information
    function order_info() view public returns (Order memory){
        return Order(address(this),owner,o_cpu,o_memory,o_storage,o_cert,o_sdl_trx_id,uint8(order_status),o_order_number);
    }
    // @dev submit server uri
    function submit_server_uri(string memory uri) only_provider public {
        server_uri = uri;
    }
    // @dev query provider address
    function query_provider_address() view external  returns(address){
        if ((order_status==OrderStatus.Ended || order_status==OrderStatus.Running) &&final_price>0){
            return provide_quotes[final_choice].provider;

        }
        return address(0);
    }

    function _pay_billing(address payable pay_target) private returns(uint256){
        uint256 pay_amount = (block.timestamp - last_pay_time) * final_price;
        if (pay_amount>address(this).balance){
            order_status = OrderStatus.Ended;
            pay_amount = address(this).balance;
            PriceOracle memory quote_detail  = provide_quotes[final_choice];
            provider_factory.recoverResource(quote_detail.provider,o_cpu, o_memory, o_storage);
            emit OrderEnded();
        }
        
        last_pay_time = block.timestamp;
        payable(pay_target).transfer(pay_amount);
        totalSpent = totalSpent+pay_amount;
        emit PayBill(pay_target,pay_amount);
        return pay_amount;
    }

    // @dev The provider invokes the payment order
    function pay_billing() only_provider nonReentrant public{
        require(block.timestamp>last_pay_time+2000,"Only one call within 2000 seconds is allowed!");
        _pay_billing(payable(msg.sender));
    }
    // @dev The user cancels the order and withdraws all remaining amounts
    function withdraw_fund() only_owner nonReentrant public{
        uint256 left_balance = address(this).balance;
        if (order_status==OrderStatus.Running){
            PriceOracle memory quote_detail  = provide_quotes[final_choice];
            left_balance = left_balance - _pay_billing(payable( IProvider( quote_detail.provider).owner()));
            if(left_balance>0){
                provider_factory.recoverResource(quote_detail.provider,o_cpu, o_memory, o_storage);
                payable(owner).transfer(left_balance);
                left_balance=0;
            }
        }
       if(left_balance>0){
           payable(owner).transfer(left_balance);
        }
        
        order_status=OrderStatus.Ended;
        emit OrderEnded();
        emit UserCancelOrder();
    }


}
