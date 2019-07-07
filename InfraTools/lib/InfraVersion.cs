using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.Text;

namespace InfraTools.lib
{
    public class InfraVersion : TableEntity
    {
        public InfraVersion()
        {

        }

        public InfraVersion(string stage, string infraName)
        {
            this.PartitionKey = stage;
            this.RowKey = infraName;
        }


        public int Version { get; set; }
    }
}
