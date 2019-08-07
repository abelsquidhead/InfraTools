using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.Text;

namespace InfraTools.lib
{
    public class MobileEnvVersion : TableEntity
    {
        public MobileEnvVersion()
        {

        }

        public MobileEnvVersion(string appName, string buildNumberServiceNameId)
        {
            this.PartitionKey = appName;
            this.RowKey = buildNumberServiceNameId;
        }

        public string EnvironmentName { get; set; }
        public string Url { get; set; }
    }
}
