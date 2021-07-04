

const API_QUOTE_URL = 'https://api.0x.org/swap/v1/quote';

function createQueryString(params) {
    return Object.entries(params).map(([k, v]) => `${k}=${v}`).join('&');
}


module.exports = {
    createQueryString,
    API_QUOTE_URL
};