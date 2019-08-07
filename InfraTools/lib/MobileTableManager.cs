using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace InfraTools.lib
{
    public class MobileTableManager
    {
        // private property  
        private CloudTable _table;

        // Constructor   
        public MobileTableManager(string _CloudTableName, string connectionString)
        {
            if (string.IsNullOrEmpty(_CloudTableName))
            {
                throw new ArgumentNullException("Table", "Table Name can't be empty");
            }
            try
            {
                string ConnectionString = connectionString;
                CloudStorageAccount storageAccount = CloudStorageAccount.Parse(ConnectionString);
                CloudTableClient tableClient = storageAccount.CreateCloudTableClient();
                _table = tableClient.GetTableReference(_CloudTableName);
                _table.CreateIfNotExistsAsync().Wait();
            }
            catch (StorageException StorageExceptionObj)
            {
                throw StorageExceptionObj;
            }
            catch (Exception ExceptionObj)
            {
                throw ExceptionObj;
            }
        }

        public async Task<MobileEnvVersion> GetMobileVersionAsync(string appName, string buildNumberServiceNameId)
        {
            // Create a retrieve operation that takes the stage (patition key) and infraName (row).
            var retrieveOperation = TableOperation.Retrieve<MobileEnvVersion>(appName, buildNumberServiceNameId);
            // Execute the retrieve operation.
            TableResult retrievedResult = await _table.ExecuteAsync(retrieveOperation);
           
            return (MobileEnvVersion)retrievedResult.Result;

        }

        public async Task AddMobileVersionAsync(string appName, string buildNumberServiceNameId, string environment, string url)
        {
            var serviceObj = await GetMobileVersionAsync(appName, buildNumberServiceNameId);
            if (serviceObj == null)
            {
                serviceObj = new MobileEnvVersion(appName, buildNumberServiceNameId)
                {
                    EnvironmentName = environment,
                    Url = url
                };
            }

            var insertOperation = TableOperation.InsertOrMerge(serviceObj);
            await _table.ExecuteAsync(insertOperation);

        }
    }
}
