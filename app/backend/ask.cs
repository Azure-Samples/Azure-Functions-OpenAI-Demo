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
                "AZURE_SEARCH_ENDPOINT",
                "%AZURE_SEARCH_INDEX%",
                Query = "{question}",
                ChatModel = "%AZURE_OPENAI_CHATGPT_DEPLOYMENT%",
                EmbeddingsModel = "%AZURE_OPENAI_EMB_DEPLOYMENT%",
                SystemPrompt = "%SYSTEM_PROMPT%"
            )]
                SemanticSearchContext result
        )
        {
            _logger.LogInformation("Ask function called...");

            var _answer = new AnswerResponse(new string[] { }, result.Response, "");

            return new OkObjectResult(_answer);
        }

        public record AnswerResponse(
            [property: JsonPropertyName("data_points")] string[] DataPoints,
            [property: JsonPropertyName("answer")] string Answer,
            [property: JsonPropertyName("thoughts")] string Thoughts
        ) { };
    }
}
