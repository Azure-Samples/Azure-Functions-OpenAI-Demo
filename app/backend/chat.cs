using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Extensions.OpenAI.Assistants;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace sample.demo
{
    public class Chat
    {
        private readonly ILogger<Chat> _logger;

        public Chat(ILogger<Chat> logger)
        {
            _logger = logger;
        }

        [Function("chat")]
        public static CreateChatBotOutput CreateAssistant(
            [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "chat/{assistantId}")]
                HttpRequestData req,
            string assistantId
        )
        {
            var responseJson = new { assistantId };

            string instructions = """
                Don't make assumptions about what values to plug into functions.
                Ask for clarification if a user request is ambiguous.
                """;

            return new CreateChatBotOutput
            {
                HttpResponse = new OkObjectResult(responseJson),
                ChatBotCreateRequest = new AssistantCreateRequest(assistantId, instructions),
            };
        }

        public class PostResponseOutput
        {

            [HttpResult]
            public IActionResult? HttpResponse { get; set; }
        }

        [Function("chatQuery")]
        public static PostResponseOutput ChatQuery(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "chat/{assistantId}")]
                HttpRequestData req,
            string assistantId,
            [AssistantPostInput(
                "{assistantId}",
                "{prompt}",
                Model = "%CHAT_MODEL_DEPLOYMENT_NAME%"
            )]
                AssistantState state
        )
        {
            // Send response to client in expected format, including assistantId
            var _answer = new answer(
                new string[] { },
                state.RecentMessages.LastOrDefault()?.Content ?? "No response returned.",
                ""
            );

            return new PostResponseOutput { HttpResponse = new OkObjectResult(_answer), };
        }

        [Function(nameof(GetChatState))]
        public static IActionResult GetChatState(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "chat/{assistantId}")]
                HttpRequestData req,
            string assistantId,
            [AssistantQueryInput("{assistantId}", TimestampUtc = "{Query.timestampUTC}")]
                AssistantState state
        )
        {
            // Returns the last message from the history table which will be the latest answer to the last question
            var _answer = new answer(
                new string[] { },
                state.RecentMessages.LastOrDefault()?.Content ?? "No response returned.",
                ""
            );

            return new OkObjectResult(_answer);
        }

        public class CreateChatBotOutput
        {
            [AssistantCreateOutput()]
            public AssistantCreateRequest? ChatBotCreateRequest { get; set; }

            [HttpResult]
            public IActionResult? HttpResponse { get; set; }
        }

        public record answer(
            [property: JsonPropertyName("data_points")] string[] DataPoints,
            [property: JsonPropertyName("answer")] string Answer,
            [property: JsonPropertyName("thoughts")] string thoughts
        ) { };
    }
}
