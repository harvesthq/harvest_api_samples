const https = require("https");

const options = {
  protocol: "https:",
  hostname: "api.harvestapp.com",
  path: "/v2/users/me",
  headers: {
    "User-Agent": "Node.js Harvest API Sample",
    "Authorization": "Bearer " + process.env.HARVEST_ACCESS_TOKEN,
    "Harvest-Account-ID": process.env.HARVEST_ACCOUNT_ID
  }
}

https.get(options, (res) => {
  const { statusCode } = res;

  if (statusCode !== 200) {
    console.error(`Request failed with status: ${statusCode}`);
    return;
  }

  res.setEncoding('utf8');
  let rawData = '';
  res.on('data', (chunk) => { rawData += chunk; });
  res.on('end', () => {
    try {
      const parsedData = JSON.parse(rawData);
      console.log(parsedData);
    } catch (e) {
      console.error(e.message);
    }
  });
}).on('error', (e) => {
  console.error(`Got error: ${e.message}`);
});
