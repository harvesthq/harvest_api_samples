function myFunction() {
  var url = "https://api.harvestapp.com/v2/users/me";
  var accessToken = "my-access-token";
  var accountID = "my-account-id";

  var headers = {
    "User-Agent": "Google Apps Script Harvest API Sample",
    "Authorization": "Bearer "+ accessToken,
    "Harvest-Account-ID": accountID
  };

  var options = {
    "method": "get",
    "headers": headers
  };

  var response = UrlFetchApp.fetch(url, options);

  Logger.log(JSON.parse(response.getContentText()));
}
