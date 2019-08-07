using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Microsoft.Extensions.Configuration;
using InfraTools.lib;

namespace InfraTools
{
    public static class MobileEnvSaver
    {
        [FunctionName("MobileEnvSaver")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            // get parameters from either param list of post body
            string appName = req.Query["appname"];
            string buildNumberServiceNameId = req.Query["buildnumberservicenameid"];
            string environment = req.Query["environment"];
            string url = req.Query["url"];

            // look at post body
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            appName = appName ?? data?.appname;
            buildNumberServiceNameId = buildNumberServiceNameId ?? data?.buildnumberservicenameid;
            environment = environment ?? data?.environment;
            url = url ?? data?.url;

            // error condition
            if (appName == null | buildNumberServiceNameId == null)
            {
                return new BadRequestObjectResult("Please pass an app name, build number service name id, environment and url on the query string or in the request body");
            }

            // get connection string
            var config = new ConfigurationBuilder()
                .AddEnvironmentVariables()
                .Build();
            var connectionString = config.GetConnectionString("myconnectionstring");

            // get a reference to the azure table and get the latest version for your stage
            var tableMgr = new MobileTableManager("MobileServiceEnv", connectionString);
            await tableMgr.AddMobileVersionAsync(appName, buildNumberServiceNameId, environment, url);

            return new OkObjectResult("ok");
        }
    }
}
