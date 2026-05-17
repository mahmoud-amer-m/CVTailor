import Foundation

private struct AnthropicResponse: Decodable {
    struct Content: Decodable {
        let type: String
        let text: String
    }
    let content: [Content]
}

enum AnthropicError: LocalizedError {
    case apiError(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .apiError(let code, let body):
            return "API error \(code): \(body)"
        case .emptyResponse:
            return "The API returned an empty response."
        }
    }
}

struct AnthropicService {
    static func tailorCV(jobDescription: String, cv: String, apiKey: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-opus-4-7",
            "max_tokens": 4096,
            "system": "You are an expert CV writer and career coach. Tailor CVs to specific job descriptions by highlighting relevant skills, incorporating keywords naturally, and optimizing the presentation while keeping all content factually accurate.",
            "messages": [
                [
                    "role": "user",
                    "content": """
                    Please tailor my CV to the job description below. \
                    Emphasize skills and experience most relevant to the role, \
                    incorporate keywords from the job description naturally, \
                    and reframe accomplishments to align with what the employer is seeking. \
                    Keep all facts accurate — only optimize the presentation. \
                    Return only the tailored CV text with no additional commentary.

                    JOB DESCRIPTION:
                    \(jobDescription)

                    MY CV:
                    \(cv)
                    """
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AnthropicError.apiError(0, "Invalid response")
        }

        guard http.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AnthropicError.apiError(http.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)

        guard let text = decoded.content.first(where: { $0.type == "text" })?.text,
              !text.isEmpty else {
            throw AnthropicError.emptyResponse
        }

        return text
    }
}
