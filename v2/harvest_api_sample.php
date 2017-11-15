<?php
  $url = "https://api.harvestapp.com/v2/users/me";
  $headers = array(
    "Authorization: Bearer " . getenv("HARVEST_ACCESS_TOKEN"),
    "Harvest-Account-ID: "   . getenv("HARVEST_ACCOUNT_ID")
  );

  $handle = curl_init();
  curl_setopt($handle, CURLOPT_URL, $url);
  curl_setopt($handle, CURLOPT_RETURNTRANSFER, 1);
  curl_setopt($handle, CURLOPT_HTTPHEADER, $headers);
  curl_setopt($handle, CURLOPT_USERAGENT, "PHP Harvest API Sample");

  $response = curl_exec($handle);

  if (curl_errno($handle)) {
    print "Error: " . curl_error($handle);
  } else {
    print json_encode(json_decode($response), JSON_PRETTY_PRINT);
    curl_close($handle);
  }
?>
