using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Extensions.OpenAI.Search;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace sample.demo
{
    public class Ask
    {
        private readonly ILogger<Ask> _logger;

        public Ask(ILogger<Ask> logger)
        {
            _logger = logger;
        }

        [Function("ask")]
        public IActionResult AskData(
            [HttpTrigger(AuthorizationLevel.Anonymous, Route = "ask")] HttpRequestData req,
            [SemanticSearchInput(
                "AISearchEndpoint",
                "openai-index",
                Query = "{question}",
                ChatModel = "%CHAT_MODEL_DEPLOYMENT_NAME%",
                EmbeddingsModel = "%EMBEDDING_MODEL_DEPLOYMENT_NAME%",
                SystemPrompt = "%SYSTEM_PROMPT%"
            )]
                SemanticSearchContext result
        )
        {
            _logger.LogInformation("Ask function called...");

            var _answer = new answer(new string[] { }, result.Response, "");

            return new OkObjectResult(_answer);
        }

        public record answer(
            [property: JsonPropertyName("data_points")] string[] DataPoints,
            [property: JsonPropertyName("answer")] string Answer,
            [property: JsonPropertyName("thoughts")] string Thoughts
        ) { };
    }
}
