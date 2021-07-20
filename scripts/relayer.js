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
        // includedSources: 'Uniswap_V2'
    }); 
    
    const quoteUrl = `https://api.0x.org/swap/v1/quote?${qs}&slippagePercentage=0.8`;
    const response = await fetch(quoteUrl);
    const quote = await response.json();
    console.log('the quote: ', quote);
    
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