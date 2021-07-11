const fetch = require("node-fetch");
const { parseUnits } = ethers.utils;
const API_QUOTE_URL = 'https://api.0x.org/swap/v1/quote';


function createQueryString(params) {
    return Object.entries(params).map(([k, v]) => `${k}=${v}`).join('&');
}


// const sellAmount = parseUnits('11184.9175', 'gwei');


//   const qs = createQueryString({
//     sellToken: 'USDC',
//     buyToken: 'BNT',
//     sellAmount
//   });

//   const quoteUrl = `${API_QUOTE_URL}?${qs}`;
//   let quote;
//   (async () => {
//     const response = await fetch(quoteUrl);
//     quote = await response.json();
//   })();
  
//   console.log(quote);
//   console.log(formatEther(quote.buyAmount));


// module.exports = quote;




module.exports = {
    createQueryString,
    API_QUOTE_URL
};