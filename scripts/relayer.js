const fetch = require("node-fetch");
// const { parseUnits } = ethers.utils;
const API_QUOTE_URL = 'https://api.0x.org/swap/v1/quote';


function createQueryString(params) {
    return Object.entries(params).map(([k, v]) => `${k}=${v}`).join('&');
}




  async function getQuote(_sellToken, _buyToken, _sellAmount) {
    const qs = createQueryString({
        sellToken: _sellToken,
        buyToken: _buyToken,
        sellAmount: _sellAmount,
        includedSources: 'Uniswap_V2'
    }); 
    
    const quoteUrl = `https://api.0x.org/swap/v1/quote?${qs}&slippagePercentage=0.8`;
    const response = await fetch(quoteUrl);
    const quote = await response.json();
    
    const addresses = [
        quote.sellTokenAddress,
        quote.buyTokenAddress,
        quote.allowanceTarget, 
        quote.to
    ];
    const bytes = quote.data;

    return { addresses, bytes };
  }
  

  async function getQuote2(_sellToken, _buyToken, _sellAmount) {
    const qs = createQueryString({
        sellToken: _sellToken,
        buyToken: _buyToken,
        sellAmount: _sellAmount,
        gas: 1500000,
        excludedSources: 'Uniswap_V3'
    }); 
    
    const quoteUrl = `https://api.0x.org/swap/v1/quote?${qs}&slippagePercentage=0.8&skipValidation=true`;
    // const quoteUrl = 'https://api.0x.org/sra/v4/orders?perPage=1000&makerToken=0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2';
    // const quoteUrl = 'https://api.0x.org/sra/v3/orders?perPage=1000&page=1&makerAssetData=0xf47261b0000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2&takerAssetData=0xf47261b00000000000000000000000000000000000085d4780b73119b644ae5ecd22b376';
    // const quoteUrl = 'http://sra-spec.s3-website-us-east-1.amazonaws.com/v2/asset_pairs';
    
    const response = await fetch(quoteUrl);
    const quote = await response.json();

    // const signatures = [];
    // for (let i = 0; i < quote.orders.length; i++) {
    //     let order = new signatureUtils.RfqOrder(quote.orders[i]);
    //     let signature = await order.getSignatureWithProviderAsync(provider);
    //     signatures.push(signature);
    // }


    // console.log('the signatures: ', signatures);
    console.log('the quote: ', quote);
    // console.log('fillData: ', quote.orders[0].fillData);
    // console.log('fillData: ', quote.orders[1].fillData);

    // console.log('order: ', quote.records[0].order);
    // console.log('meta data: ', quote.records[0].metaData);

    // console.log('second: ', quote.orders[1].fillData);
    // const obj = (quote.sources).find(obj => obj.hops);
    // console.log('hops: ', obj.hops);

    // const obj = quote.records.find(ord => parseInt(ord.order.makerAmount) >= 224817300000000000000);
    // console.log('i found it: ', obj);

    // const obj = quote.records.find(ord => parseInt(ord.order.makerAssetAmount) >= 224817300000000000000);
    // console.log('found it: ', obj);

    // console.log('the orders start here.................')
    // for (let i = 0; i < quote.records.length; i++) {
    //     console.log(quote.records[i].order);
    // }

    const addresses = [
        quote.sellTokenAddress,
        quote.buyTokenAddress,
        quote.allowanceTarget, 
        quote.to
    ];
    const bytes = quote.data;

    return { addresses, bytes };
  }







module.exports = {
    createQueryString,
    API_QUOTE_URL,
    getQuote,
    getQuote2,
    
};