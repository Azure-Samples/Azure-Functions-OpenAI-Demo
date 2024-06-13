using System.Net;
using HttpMultipartParser;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Extensions.OpenAI.Embeddings;
using Microsoft.Azure.Functions.Worker.Extensions.OpenAI.Search;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace sample.demo
{
    public class Upload
    {
        private readonly ILogger<Upload> _logger;

        public Upload(ILogger<Upload> logger)
        {
            _logger = logger;
        }

        /// <summary>
        /// Uploads the file Azure Files and adds the file location to the queue message.
        /// The file location is then retrieved by the queue trigger to embed the content by the EmbedContent function.
        /// </summary>
        /// <param name="req"></param>
        /// <returns></returns>
        [Function("upload")]
        public static async Task<QueueHttpResponse> UploadFile(
            [HttpTrigger(AuthorizationLevel.Anonymous, Route = "upload")] HttpRequestData req
        )
        {
            var fileShare =
                Environment.GetEnvironmentVariable("fileShare") ?? "/mounts/openaifiles";
            // Read file from request
            var parsedFormBody = await MultipartFormDataParser.ParseAsync(req.Body);
            QueuePayload[] payload = new QueuePayload[] { };

            // Save file to Azure Files and add file location to queue message
            foreach (var file in parsedFormBody.Files)
            {
                var reader = new StreamReader(file.Data);
                var fileStream = File.Create(Path.Combine(fileShare, file.FileName));
                reader.BaseStream.Seek(0, SeekOrigin.Begin);
                reader.BaseStream.CopyTo(fileStream);
                fileStream.Close();
                var queueMessage = new QueuePayload
                {
                    FileName = Path.Combine(fileShare, file.FileName)
                };
                payload = payload.Append(queueMessage).ToArray();
            }

            var result = new UploadResponse("File uploaded successfully", true);
            // Return queue message and response as output
            return new QueueHttpResponse
            {
                QueueMessage = payload,
                HttpResponse = new OkObjectResult(result)
            };
        }

        [Function("EmbedContent")]
        public static EmbeddingsStoreOutputResponse EmbedContent(
            [ServiceBusTrigger("%ServiceBusQueueName%", Connection = "serviceBusConnection")]
                QueuePayload queueItem
        )
        {
            return new EmbeddingsStoreOutputResponse
            {
                SearchableDocument = new SearchableDocument(queueItem.FileName ?? "")
            };
        }

        public class EmbeddingsStoreOutputResponse
        {
            [EmbeddingsStoreOutput(
                "{FileName}",
                InputType.FilePath,
                "AISearchEndpoint",
                "openai-index",
                Model = "%EMBEDDING_MODEL_DEPLOYMENT_NAME%"
            )]
            public required SearchableDocument SearchableDocument { get; init; }
        }

        public class QueueHttpResponse
        {
            [ServiceBusOutput("%ServiceBusQueueName%", Connection = "serviceBusConnection")]
            public QueuePayload[]? QueueMessage { get; set; }

            [HttpResult]
            public IActionResult? HttpResponse { get; set; }
        }

        public class QueuePayload
        {
            public string? FileName { get; set; }
        }

        public record UploadResponse(string Message, bool Success);
    }
}
