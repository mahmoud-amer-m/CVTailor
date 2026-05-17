import Foundation

private struct AnthropicResponse: Decodable {
    struct Content: Decodable {
        let type: String
        let text: String
    }
    let content: [Content]
}

private struct AnthropicErrorBody: Decodable {
    struct Detail: Decodable {
        let message: String
    }
    let error: Detail
}

enum AnthropicError: LocalizedError {
    case invalidAPIKey
    case permissionDenied
    case rateLimited
    case serverOverloaded
    case serverError(Int)
    case invalidRequest(String)
    case networkError(String)
    case emptyResponse
    case unexpectedResponse

    var errorTitle: String {
        switch self {
        case .invalidAPIKey:        return "Invalid API Key"
        case .permissionDenied:     return "Permission Denied"
        case .rateLimited:          return "Rate Limit Reached"
        case .serverOverloaded:     return "Server Overloaded"
        case .serverError:          return "Server Error"
        case .invalidRequest:       return "Invalid Request"
        case .networkError:         return "Network Error"
        case .emptyResponse,
             .unexpectedResponse:   return "Unexpected Response"
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "The API key is invalid. Double-check the key in the form."
        case .permissionDenied:
            return "Your API key does not have permission to use this model."
        case .rateLimited:
            return "Rate limit reached. Wait a moment, then try again."
        case .serverOverloaded:
            return "Anthropic's servers are currently overloaded. Try again shortly."
        case .serverError(let code):
            return "Server error (\(code)). Try again in a few moments."
        case .invalidRequest(let message):
            return message
        case .networkError(let message):
            return message
        case .emptyResponse:
            return "The API returned an empty response. Please try again."
        case .unexpectedResponse:
            return "Received an unexpected response. Please try again."
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

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            throw AnthropicError.networkError(urlError.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AnthropicError.unexpectedResponse
        }

        guard http.statusCode == 200 else {
            let detail = try? JSONDecoder().decode(AnthropicErrorBody.self, from: data)
            switch http.statusCode {
            case 401: throw AnthropicError.invalidAPIKey
            case 403: throw AnthropicError.permissionDenied
            case 429: throw AnthropicError.rateLimited
            case 529: throw AnthropicError.serverOverloaded
            case 400: throw AnthropicError.invalidRequest(detail?.error.message ?? "Invalid request.")
            default:  throw AnthropicError.serverError(http.statusCode)
            }
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)

        guard let text = decoded.content.first(where: { $0.type == "text" })?.text,
              !text.isEmpty else {
            throw AnthropicError.emptyResponse
        }

        return text
    }
}
