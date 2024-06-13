import { AskRequest, AskResponse, ChatRequest, UploadFileRequest, UploadFileResponse, NewChatResponse } from "./models";
 
export async function askApi(options: AskRequest): Promise<AskResponse> {
  const response = await fetch("/api/ask", {
      method: "POST",
      headers: {
          "Content-Type": "application/json"
      },
      body: JSON.stringify({
          question: options.question,
          approach: options.approach,
          overrides: {
              semantic_ranker: options.overrides?.semanticRanker,
              semantic_captions: options.overrides?.semanticCaptions,
              top: options.overrides?.top,
              temperature: options.overrides?.temperature,
              prompt_template: options.overrides?.promptTemplate,
              prompt_template_prefix: options.overrides?.promptTemplatePrefix,
              prompt_template_suffix: options.overrides?.promptTemplateSuffix,
              exclude_category: options.overrides?.excludeCategory
          }
      })
  });
 
  const parsedResponse: AskResponse = await response.json();
  if (response.status > 299 || !response.ok) {
      throw Error(parsedResponse.error || "Unknown error");
  }
 
  return parsedResponse;
}
 
export async function chatApi(options: ChatRequest): Promise<AskResponse> {
  const response = await fetch("/api/chat/" + globalThis.assistantId, {
      method: "POST",
      headers: {
          "Content-Type": "application/json"
      },
      body: JSON.stringify({
          history: options.history,
          prompt: options.history[options.history.length-1].user,
          approach: options.approach,
          overrides: {
              semantic_ranker: options.overrides?.semanticRanker,
              semantic_captions: options.overrides?.semanticCaptions,
              top: options.overrides?.top,
              temperature: options.overrides?.temperature,
              prompt_template: options.overrides?.promptTemplate,
              prompt_template_prefix: options.overrides?.promptTemplatePrefix,
              prompt_template_suffix: options.overrides?.promptTemplateSuffix,
              exclude_category: options.overrides?.excludeCategory,
              suggest_followup_questions: options.overrides?.suggestFollowupQuestions
          }
      })
  });
 
  const parsedResponse: AskResponse = await response.json();
  if (response.status > 299 || !response.ok) {
      throw Error(parsedResponse.error || "Unknown error");
  }
 
  return parsedResponse;
}
 
export function getCitationFilePath(citation: string): string {
  return `/api/content/${citation}`;
}

export async function getUserId(): Promise<string> {
  const response = await fetch('/.auth/me');
  const payload = await response.json();
  const {clientPrincipal} = payload;
  globalThis.assistantId = clientPrincipal.userId;

  // Check if user has chat history
  const chatHistoryResponse = await fetch('/api/chat/' + globalThis.assistantId + '?timestampUTC=2023-01-01T00:00:00Z', {
    method: "GET",});

  const chatHistory = await chatHistoryResponse.json();

  // If no chat history, create a new chat
  if (chatHistory.answer == "No response returned.") {
    newChat(globalThis.assistantId);
  }
  return clientPrincipal.userId
}

export async function newChat(
  chatId: string
): Promise<NewChatResponse> {
  const response = await fetch('/api/chat/' + chatId, {
    method: "PUT",
  });
 
  const parsedResponse: NewChatResponse = await response.json();
 
  if (response.status > 299 || !response.ok) {
    throw Error(
       `Failed to create chat: ${response.statusText}`
    );
  }
  return parsedResponse;
}

export async function uploadApi(
  request: UploadFileRequest
): Promise<UploadFileResponse> {
  const response = await fetch("/api/upload", {
    method: "POST",
    body: request.formData,
  });
 
  const parsedResponse: UploadFileResponse = await response.json();
 
  if (response.status > 299 || !response.ok) {
    throw Error(
      parsedResponse.error || `Failed to upload file: ${response.statusText}`
    );
  }
 
  return parsedResponse;
}
 