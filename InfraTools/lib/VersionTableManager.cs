using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace InfraTools.lib
{
    public class VersionTableManager
    {
        // private property  
        private CloudTable _table;

        // Constructor   
        public VersionTableManager(string _CloudTableName, string connectionString)
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

        public async Task<InfraVersion> GetInfraVersionAsync(string stage, string infraName)
        {
            // Create a retrieve operation that takes the stage (patition key) and infraName (row).
            var retrieveOperation = TableOperation.Retrieve<InfraVersion>(stage, infraName);
            // Execute the retrieve operation.
            TableResult retrievedResult = await _table.ExecuteAsync(retrieveOperation);
            // value doesn't exist in db
            if (retrievedResult.Result == null)
            {
                // create the row, set version to zero
                var newRowValue = new InfraVersion(stage, infraName);
                newRowValue.Version = 0;
                // add to db
                await AddInfraVersionAsync(newRowValue);
                // set to result so the newly added row will get returned
                retrievedResult.Result = newRowValue;
            }
            return (InfraVersion)retrievedResult.Result;

        }

        public async Task AddInfraVersionAsync(string stage, string infraName)
        {
            var infraObj = await GetInfraVersionAsync(stage, infraName);
            infraObj.Version++;

            var insertOperation = TableOperation.InsertOrMerge(infraObj);
            await _table.ExecuteAsync(insertOperation);

        }

        private async Task AddInfraVersionAsync(InfraVersion version)
        {
            var insertOperation = TableOperation.InsertOrMerge(version);
            await _table.ExecuteAsync(insertOperation);
        }

    }
}
