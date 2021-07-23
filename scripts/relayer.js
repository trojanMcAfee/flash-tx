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

/***** last function that executes *****/
  async function getQuote2(_sellToken, _buyToken, _sellAmount) {
    const qs = createQueryString({ //try to find the order directly through tenderly and 0x's order book or relayer API 
        sellToken: _sellToken,
        buyToken: _buyToken,
        sellAmount: _sellAmount,
        // includedSources: 'Uniswap_V2'
    }); 
    
    const quoteUrl = `https://api.0x.org/swap/v1/quote?${qs}&slippagePercentage=0.8`;
    // const quoteUrl = 'https://api.0x.org/sra/orders?makerAssetData=0xf47261b0000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'

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
    // console.log(quote.records[0].order);
    // console.log('first: ', quote.orders[0].fillData);
    // console.log('second: ', quote.orders[1].fillData);
    // const obj = (quote.sources).find(obj => obj.hops);
    // console.log('hops: ', obj.hops);
    
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
    getQuote2
};