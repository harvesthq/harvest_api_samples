require "net/http"
require "json"

PERSONAL_ACCESS_TOKEN = ENV["HARVEST_ACCESS_TOKEN"]
ACCOUNT_ID = ENV["HARVEST_ACCOUNT_ID"]

uri = URI("https://api.harvestapp.com/v2/users/me")

Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
  request = Net::HTTP::Get.new uri
  request["User-Agent"] = "Ruby Harvest API Sample"
  request["Authorization"] = "Bearer #{PERSONAL_ACCESS_TOKEN}"
  request["Harvest-Account-ID"] = ACCOUNT_ID

  response = http.request request
  json_response = JSON.parse(response.body)

  puts JSON.pretty_generate(json_response)
end
