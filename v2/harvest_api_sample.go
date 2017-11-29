package main

import "fmt"
import "io/ioutil"
import "encoding/json"
import "net/http"
import "os"

func main() {
  url := "https://api.harvestapp.com/v2/users/me"
  client := &http.Client{}

  req, _ := http.NewRequest("GET", url, nil)
  req.Header.Set("User-Agent", "Go Harvest API Sample")
  req.Header.Set("Harvest-Account-ID", os.Getenv("HARVEST_ACCOUNT_ID"))
  req.Header.Set("Authorization", "Bearer " + os.Getenv("HARVEST_ACCESS_TOKEN"))

  resp, _ := client.Do(req)
  body, _ := ioutil.ReadAll(resp.Body)
  defer resp.Body.Close()

  var jsonResponse map[string]interface{}

  json.Unmarshal(body, &jsonResponse)

  prettyJson, _ := json.MarshalIndent(jsonResponse, "", "  ")
	fmt.Println(string(prettyJson))
}
