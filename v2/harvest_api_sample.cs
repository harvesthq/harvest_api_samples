using System;

namespace HarvestAPISample
{
    class MainClass
    {
        public static void Main(string[] args)
        {
            const string URL = "https://api.harvestapp.com/v2/users/me";
            try
            {
                var webRequest = System.Net.WebRequest.CreateHttp(URL);
                if (webRequest != null)
                {
                    webRequest.Method = "GET";
                    webRequest.UserAgent = "C# Harvest API Sample";
                    webRequest.Headers.Add("Authorization", "Bearer " + Environment.GetEnvironmentVariable("HARVEST_ACCESS_TOKEN"));
                    webRequest.Headers.Add("Harvest-Account-ID", Environment.GetEnvironmentVariable("HARVEST_ACCOUNT_ID"));

                    using (System.IO.Stream s = webRequest.GetResponse().GetResponseStream())
                    {
                        using (System.IO.StreamReader sr = new System.IO.StreamReader(s))
                        {
                            var jsonResponse = sr.ReadToEnd();
                            Console.WriteLine(jsonResponse);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }
    }
}
