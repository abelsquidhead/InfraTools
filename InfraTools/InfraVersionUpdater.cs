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
    public static class InfraVersionUpdater
    {
        [FunctionName("InfraVersionUpdater")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            // get parameters from either param list of post body
            string tablename = req.Query["tablename"];
            string stage = req.Query["stage"];
            string infraname = req.Query["infraname"];

            // look at post body
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            tablename = tablename ?? data?.tablename;
            stage = stage ?? data?.name;
            infraname = infraname ?? data?.infraname;

            // error condition
            if (tablename == null | stage == null | infraname == null)
            {
                return new BadRequestObjectResult("Please pass a table name, stage and infrastructure name on the query string or in the request body");
            }

            // get connection string
            var config = new ConfigurationBuilder()
                .AddEnvironmentVariables()
                .Build();
            var connectionString = config.GetConnectionString("myconnectionstring");

            // get a reference to the azure table and get the latest version for your stage
            var tableMgr = new TableManager(tablename, connectionString);
            await tableMgr.AddInfraVersionAsync(stage, infraname);

            return new OkObjectResult("ok");
        }
    }
}
