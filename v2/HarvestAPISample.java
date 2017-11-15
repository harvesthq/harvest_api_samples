import java.io.*;
import java.net.*;

public class HarvestAPISample {
  public static void main(String[] args) throws IOException, ProtocolException {
    URL url = new URL("https://api.harvestapp.com/v2/users/me");
    HttpURLConnection conn = (HttpURLConnection) url.openConnection();

    conn.setRequestMethod("GET");
    conn.setRequestProperty("Accept", "application/json");
    conn.setRequestProperty("User-Agent", "Java Harvest API Sample");
    conn.setRequestProperty("Authorization", "Bearer " + System.getenv("HARVEST_ACCESS_TOKEN"));
    conn.setRequestProperty("Harvest-Account-ID", System.getenv("HARVEST_ACCOUNT_ID"));

    String inputLine;
    BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
    StringBuffer response = new StringBuffer();

    while ((inputLine = in.readLine()) != null) {
      response.append(inputLine);
    }

    if (conn.getResponseCode() == 200) {
      System.out.println(response);
    } else {
      System.out.println("Error " + conn.getResponseCode() + ": " + response);
    }

    in.close();
    conn.disconnect();
  }
}
