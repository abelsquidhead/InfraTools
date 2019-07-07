using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using DnsClient;
using DnsClient.Protocol;

namespace InfraTools
{
    public static class DNSAliasChecker
    {
        [FunctionName("DNSAliasChecker")]
        public static async Task<IActionResult> Run(
             [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            // parse fqdn and alias from request
            string fqdn = req.Query["fqdn"];
            string alias = req.Query["alias"];

            // parse fqdn and alias from request body of a post
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);

            // set the value whether it came from param list or post body
            fqdn = fqdn ?? data?.fqdn;
            alias = alias ?? data?.alias;

            // if user didn't pass in fqdn or alias, return with bad request
            if ((fqdn == null) || (alias == null))
            {
                return new BadRequestObjectResult("Please pass the fqdn and alis on the query string or in the request body");
            }

            // query dns for your fqdn and cname/alias, loop through all
            // returned values and see if you cand find your cname
            var lookupClient = new LookupClient();
            var result = lookupClient.Query(fqdn, QueryType.CNAME);
            var foundEntry = false;
            foreach (var record in result.Answers)
            {
                var cnameRecord = record as CNameRecord;
                var cname = cnameRecord.CanonicalName.Value.ToString();
                // check if it has trailing .
                if (cname.EndsWith("."))
                {
                    cname = cname.Remove(cname.Length - 1);
                }
                if (cname.Equals(alias))
                {
                    foundEntry = true;
                    break;
                }
            }

            // return result
            if (foundEntry)
            {
                return new OkObjectResult(true);
            }
            return new OkObjectResult(false);

        }
    }
}
