import { BigNumber } from "ethers";

const {ethers,network} = require('hardhat')
import chai, { expect } from "chai";
import type {OrderBase,OrderFactory,ProviderFactory,Cert} from "../../types";


describe('order factory',function(){
  let factory_admin:any,order_1:any,order_2:any,provider_factory_admin:any,provider_1:any,provider_2:any;
  let zero_addr: string = '0x0000000000000000000000000000000000000000' ;
  let mock_addr: string = '0x00000000000000000000000000000000000004CF';
  beforeEach(async function() {
      [factory_admin, order_1, order_2, provider_factory_admin,provider_1,provider_2] = await ethers.getSigners();
      this.orderFactory = await (await ethers.getContractFactory('OrderFactory',factory_admin)).deploy();

      this.providerFactory = await (await ethers.getContractFactory('ProviderFactory', factory_admin)).deploy();
      this.certCenter = await (await ethers.getContractFactory('Cert', factory_admin)).deploy();
    }
    )
  it('init',async function(){

    expect(await this.orderFactory.owner()).to.be.equal(factory_admin.address);
    await expect(this.orderFactory.createOrder(100,1000,1000000,"dsadsa","dsadasda")).to.be.revertedWith('please wait admin set provider factory!');
    await  this.orderFactory.set_provider_factory(this.providerFactory.address);
    await expect(this.orderFactory.createOrder(100,1000,1000000,"dsadsa","dsadasda")).to.be.revertedWith('please wait admin set cert center!');

  })
  it("create order", async function() {
    await  this.orderFactory.set_provider_factory(this.providerFactory.address);
    await  this.orderFactory.set_cert_center(this.certCenter.address);
    await  this.orderFactory.connect(order_1).createOrder(100,1000,100000,"dsdas","dsdasdadas");

    await this.orderFactory.connect(order_2).createOrder(200,2000,200000,"dsdas","dsdasdadas");


    expect(await this.orderFactory.orders(1)).to.be.not.equal(zero_addr);
    expect(await this.orderFactory.orders(2)).to.be.not.equal(zero_addr);
    let order_base_address_1 =  await this.orderFactory.orders(1);
    let order_base_address_2 = await this.orderFactory.orders(2);
    this.order_base_1 = <OrderBase>await ethers.getContractAt("OrderBase",order_base_address_1);
    this.order_base_2 = <OrderBase>await ethers.getContractAt("OrderBase",order_base_address_2);

    expect(await this.order_base_1.o_cpu()).to.be.equal(100);
    expect(await this.order_base_1.o_memory()).to.be.equal(1000);
    expect(await this.order_base_1.o_storage()).to.be.equal(100000);
    expect(await this.order_base_1.o_order_number()).to.be.equal(1);
    expect(await this.order_base_1.o_cert()).to.be.equal("dsdas");
    expect(await this.order_base_1.o_sdl_trx_id()).to.be.equal("dsdasdadas");
    expect(await this.order_base_1.owner()).to.be.equal(order_1.address);
    expect(await this.order_base_2.o_cpu()).to.be.equal(200);
    expect(await this.order_base_2.o_memory()).to.be.equal(2000);
    expect(await this.order_base_2.o_storage()).to.be.equal(200000);
    expect(await this.order_base_2.o_order_number()).to.be.equal(2);
    expect(await this.order_base_2.o_cert()).to.be.equal("dsdas");
    expect(await this.order_base_2.o_sdl_trx_id()).to.be.equal("dsdasdadas");
    expect(await this.order_base_2.owner()).to.be.equal(order_2.address);

  });
  it("deposit_balance", async function() {
    await  this.orderFactory.set_provider_factory(this.providerFactory.address);
    await  this.orderFactory.set_cert_center(this.certCenter.address);
    await  this.orderFactory.connect(order_1).createOrder(100,1000,100000,"dsdas","dsdasdadas");
    await this.orderFactory.connect(order_2).createOrder(200,2000,200000,"dsdas","dsdasdadas");
    let order_base_address_1 =  await this.orderFactory.orders(1);
    let order_base_address_2 = await this.orderFactory.orders(2);
    this.order_base_1 = <OrderBase>await ethers.getContractAt("OrderBase",order_base_address_1);
    this.order_base_2 = <OrderBase>await ethers.getContractAt("OrderBase",order_base_address_2);

    let unCompleteOrder =await this.orderFactory.getUnCompleteOrder();

      await expect(this.order_base_1.connect(provider_1).quote(1000,1000,200)).to.be.reverted;
      await expect(this.order_base_1.connect(provider_2).quote(1000,1000,200)).to.be.reverted;
    expect(await this.order_base_1.order_status()).to.be.equal(0);
      await expect(this.order_base_1.connect(order_1).deposit_balance({value:ethers.utils.parseEther("1")})).to.be.reverted;
      expect(await this.order_base_1.connect(order_1).deposit_balance({value:ethers.utils.parseEther("5")}));
    unCompleteOrder =await this.orderFactory.getUnCompleteOrder();
    expect(unCompleteOrder.length).to.be.equal(1);
    expect(unCompleteOrder[0].owner ).to.be.equal(order_1.address);
    await expect(this.order_base_1.connect(provider_1).quote(1000,1000,200));
    await expect(this.order_base_1.connect(provider_2).quote(2000,2000,400));

    let [a,b,c,d] = await this.order_base_1.provide_quotes(0);

    expect(a).to.be.equal(mock_addr);
    expect(b).to.be.equal(1000);
    expect(c).to.be.equal(1000);
    expect(d).to.be.equal(200);
    [a,b,c,d] = await this.order_base_1.provide_quotes(1);

    expect(a).to.be.equal(mock_addr);
    expect(b).to.be.equal(2000);
    expect(c).to.be.equal(2000);
    expect(d).to.be.equal(400);
    expect(await this.order_base_1.order_status()).to.be.equal(1);



    await expect(this.order_base_2.connect(provider_1).quote(1000,1000,200)).to.be.reverted;
    await expect(this.order_base_2.connect(provider_2).quote(1000,1000,200)).to.be.reverted;
    await expect(this.order_base_2.connect(order_2).deposit_balance({value:ethers.utils.parseEther("1")})).to.be.reverted;
    expect(await this.order_base_2.connect(order_2).deposit_balance({value:ethers.utils.parseEther("5")}));
    await expect(this.order_base_2.connect(provider_1).quote(1000,1000,200));
    await expect(this.order_base_2.connect(provider_2).quote(2000,2000,400));
    unCompleteOrder =await this.orderFactory.getUnCompleteOrder();

    expect(unCompleteOrder.length).to.be.equal(2);
    expect(unCompleteOrder[1].owner ).to.be.equal(order_2.address);
    [a,b,c,d] = await this.order_base_2.provide_quotes(0);
    expect(a).to.be.equal(mock_addr);
    expect(b).to.be.equal(1000);
    expect(c).to.be.equal(1000);
    expect(d).to.be.equal(200);
    [a,b,c,d] = await this.order_base_2.provide_quotes(1);
    expect(a).to.be.equal(mock_addr);
    expect(b).to.be.equal(2000);
    expect(c).to.be.equal(2000);
    expect(d).to.be.equal(400);



  });
  it("choose_provider", async function() {
    await  this.orderFactory.set_provider_factory(this.providerFactory.address);
    await  this.orderFactory.set_cert_center(this.certCenter.address);
    await  this.orderFactory.connect(order_1).createOrder(100,1000,100000,"dsdas","dsdasdadas");
    await this.orderFactory.connect(order_2).createOrder(200,2000,200000,"dsdas","dsdasdadas");
    let order_base_address_1 =  await this.orderFactory.orders(1);
    let order_base_address_2 = await this.orderFactory.orders(2);
    this.order_base_1 = <OrderBase>await ethers.getContractAt("OrderBase",order_base_address_1);
    this.order_base_2 = <OrderBase>await ethers.getContractAt("OrderBase",order_base_address_2);
    expect(await this.order_base_1.connect(order_1).deposit_balance({value:ethers.utils.parseEther("5")}));
    expect(await this.order_base_2.connect(order_2).deposit_balance({value:ethers.utils.parseEther("5")}));
    await expect(this.order_base_1.connect(provider_1).quote(1000,1000,200));
    await expect(this.order_base_1.connect(provider_2).quote(2000,2000,400));
    await expect(this.order_base_2.connect(provider_1).quote(1000,1000,200));
    await expect(this.order_base_2.connect(provider_2).quote(2000,2000,400));
    expect(await this.order_base_1.order_status()).to.be.equal(1);
    await expect(this.order_base_1.connect(order_2).choose_provider(0)).to.be.reverted;
    expect(await this.order_base_1.connect(order_1).choose_provider(0));
    expect(await this.order_base_1.order_status()).to.be.equal(2);
    await expect(this.order_base_1.connect(order_1).choose_provider(1)).to.be.reverted;
    expect(await this.order_base_1.final_price()).to.be.equal(ethers.BigNumber.from(((100*1000)+(1000*1000)+(100000*200)) ));
    let unCompleted =  await this.orderFactory.getUnCompleteOrder();
    expect(unCompleted.length).to.be.equal(1);
    // let block = await ethers.provider.getBlock("latest");

    let start_time = await this.order_base_1.last_pay_time();
    // let start_time= BigNumber.from(111);
    // start_time.toNumber()
    await network.provider.request({
      method: "evm_setNextBlockTimestamp",
      params: [start_time.toNumber() + 0xfa0],
    });

    let old_balance = await ethers.provider.getBalance(provider_1.address);
    let pay_billing =await this.order_base_1.connect(provider_1).pay_billing();
    let receipt = await pay_billing.wait();
    var gasUsed = receipt.effectiveGasPrice.mul(receipt.gasUsed);
    //let transaction_fee =  res.gasLimit * res.
    let new_balance = await ethers.provider.getBalance(provider_1.address);
    expect(new_balance.sub(old_balance).add(gasUsed)).to.be.equal(ethers.BigNumber.from(((100*1000)+(1000*1000)+(100000*200))*4000 ));

  });


  it("choose_provider and pay all fee", async function() {
    await  this.orderFactory.set_provider_factory(this.providerFactory.address);
    await  this.orderFactory.set_cert_center(this.certCenter.address);
    await  this.orderFactory.connect(order_1).createOrder(100,1000,100000,"dsdas","dsdasdadas");

    let order_base_address_1 =  await this.orderFactory.orders(1);

    this.order_base_1 = <OrderBase>await ethers.getContractAt("OrderBase",order_base_address_1);

    expect(await this.order_base_1.connect(order_1).deposit_balance({value:ethers.utils.parseEther("5")}));

    await expect(this.order_base_1.connect(provider_1).quote(10000000,10000000,2000000));
    await expect(this.order_base_1.connect(provider_2).quote(20000000,20000000,4000000));

    expect(await this.order_base_1.order_status()).to.be.equal(1);
    await expect(this.order_base_1.connect(order_2).choose_provider(0)).to.be.reverted;
    expect(await this.order_base_1.connect(order_1).choose_provider(0));
    expect(await this.order_base_1.order_status()).to.be.equal(2);
    await expect(this.order_base_1.connect(order_1).choose_provider(1)).to.be.reverted;
    expect(await this.order_base_1.final_price()).to.be.equal(ethers.BigNumber.from(((100*10000000)+(1000*10000000)+(100000*2000000)) ));
    let unCompleted =  await this.orderFactory.getUnCompleteOrder();
    expect(unCompleted.length).to.be.equal(0);
    // let block = await ethers.provider.getBlock("latest");

    let start_time = await this.order_base_1.last_pay_time();
    // let start_time= BigNumber.from(111);
    // start_time.toNumber()
    await network.provider.request({
      method: "evm_setNextBlockTimestamp",
      params: [start_time.toNumber() + 0x16e3600],
    });

    let old_balance = await ethers.provider.getBalance(provider_1.address);
    let pay_billing =await this.order_base_1.connect(provider_1).pay_billing();
    let receipt = await pay_billing.wait();
    var gasUsed = receipt.effectiveGasPrice.mul(receipt.gasUsed);
    //let transaction_fee =  res.gasLimit * res.
    let new_balance = await ethers.provider.getBalance(provider_1.address);
    expect(new_balance.sub(old_balance).add(gasUsed)).to.be.equal(ethers.utils.parseEther("5"));
    expect(await ethers.provider.getBalance(this.order_base_1.address)).to.be.equal(0);

  });


  it("choose_provider and query", async function() {
    await  this.orderFactory.set_provider_factory(this.providerFactory.address);
    await  this.orderFactory.set_cert_center(this.certCenter.address);
    await  this.orderFactory.connect(order_1).createOrder(100,1000,100000,"dsdas","dsdasdadas");

    let order_base_address_1 =  await this.orderFactory.orders(1);

    this.order_base_1 = <OrderBase>await ethers.getContractAt("OrderBase",order_base_address_1);

    expect(await this.order_base_1.connect(order_1).deposit_balance({value:ethers.utils.parseEther("5")}));

    await expect(this.order_base_1.connect(provider_1).quote(10000000,10000000,2000000));
    await expect(this.order_base_1.connect(provider_2).quote(20000000,20000000,4000000));

    expect(await this.order_base_1.order_status()).to.be.equal(1);
    await expect(this.order_base_1.connect(order_2).choose_provider(0)).to.be.reverted;
    expect(await this.order_base_1.connect(order_1).choose_provider(0));
    expect(await this.order_base_1.order_status()).to.be.equal(2);
    await expect(this.order_base_1.connect(order_1).choose_provider(1)).to.be.reverted;
    expect(await this.order_base_1.final_price()).to.be.equal(ethers.BigNumber.from(((100*10000000)+(1000*10000000)+(100000*2000000)) ));
    let unCompleted =  await this.orderFactory.getUnCompleteOrder();
    expect(unCompleted.length).to.be.equal(0);
    let userOrders =  await this.orderFactory.getUserAllOrder(order_1.address);
    expect(userOrders.length).to.be.equal(1);
    let providerOrders =  await this.orderFactory.getProviderAllOrder(mock_addr);
    expect(providerOrders.length).to.be.equal(1);
    // let block = await ethers.provider.getBlock("latest");

    let start_time = await this.order_base_1.last_pay_time();
    // let start_time= BigNumber.from(111);
    // start_time.toNumber()
    await network.provider.request({
      method: "evm_setNextBlockTimestamp",
      params: [start_time.toNumber() + 0x16e3600],
    });

    let old_balance = await ethers.provider.getBalance(provider_1.address);
    let pay_billing =await this.order_base_1.connect(provider_1).pay_billing();
    let receipt = await pay_billing.wait();
    var gasUsed = receipt.effectiveGasPrice.mul(receipt.gasUsed);
    //let transaction_fee =  res.gasLimit * res.
    let new_balance = await ethers.provider.getBalance(provider_1.address);
    expect(new_balance.sub(old_balance).add(gasUsed)).to.be.equal(ethers.utils.parseEther("5"));
    expect(await ethers.provider.getBalance(this.order_base_1.address)).to.be.equal(0);

  });


  it("withdraw fund", async function() {
    await  this.orderFactory.set_provider_factory(this.providerFactory.address);
    await  this.orderFactory.set_cert_center(this.certCenter.address);
    await  this.orderFactory.connect(order_1).createOrder(100,1000,100000,"dsdas","dsdasdadas");
    await this.orderFactory.connect(order_2).createOrder(200,2000,200000,"dsdas","dsdasdadas");
    let order_base_address_1 =  await this.orderFactory.orders(1);
    let order_base_address_2 = await this.orderFactory.orders(2);
    this.order_base_1 = <OrderBase>await ethers.getContractAt("OrderBase",order_base_address_1);
    this.order_base_2 = <OrderBase>await ethers.getContractAt("OrderBase",order_base_address_2);
    expect(await this.order_base_1.connect(order_1).deposit_balance({value:ethers.utils.parseEther("5")}));
    expect(await this.order_base_2.connect(order_2).deposit_balance({value:ethers.utils.parseEther("5")}));


    let old_balance = await ethers.provider.getBalance(order_1.address);
    let pay_billing =await this.order_base_1.connect(order_1).withdraw_fund();
    let receipt = await pay_billing.wait();
    var gasUsed = receipt.effectiveGasPrice.mul(receipt.gasUsed);
    //let transaction_fee =  res.gasLimit * res.
    let new_balance = await ethers.provider.getBalance(order_1.address);
    expect(new_balance.sub(old_balance).add(gasUsed)).to.be.equal(ethers.BigNumber.from(ethers.utils.parseEther("5")));
    expect(await this.order_base_1.order_status()).to.be.equal(3);
  });

})
