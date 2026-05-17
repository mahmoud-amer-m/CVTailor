# CVTailor

A native iOS app built to demonstrate AI-driven mobile development — part of an ongoing effort to showcase practical integrations between Apple frameworks and large language models. Paste or import your CV (PDF or text), provide a job description, and receive an AI-tailored version exported as a PDF or plain-text file, all powered by the Anthropic API.

## Features

- **CV input** — paste/type text or import a PDF (text extracted via PDFKit)
- **Job description input** — paste any job posting
- **AI tailoring** — sends both to Claude via the Anthropic API and returns a rewritten CV that highlights relevant skills and incorporates keywords naturally
- **Loading overlay** — full-screen progress indicator while the API call is in progress
- **Error handling** — typed errors per HTTP status code (invalid key, rate limit, server overload, network failure, etc.) with a named alert title and a one-tap retry action
- **Format-matched PDF export** — when the input is a PDF, the exported PDF matches the original's page size, font family, font sizes, and text colors; section headers and the name line are styled independently from body text
- **Hyperlink preservation** — URLs detected in the tailored text are rendered underlined and embedded as clickable PDF link annotations using `CGContext.setURL(_:for:)`
- **Clear button** — trash icon in the navigation bar clears all input fields with a confirmation prompt
- **Export** — share the result as a multi-page PDF or a `.txt` file via the system share sheet

## Requirements

- Xcode 26+
- iOS 26+ deployment target
- An [Anthropic API key](https://console.anthropic.com/)

## Getting Started

1. Clone the repo and open `CVTailor.xcodeproj` in Xcode.
2. Set your development team under **Signing & Capabilities**.
3. Build and run on a simulator or device.
4. Enter your Anthropic API key in the **API Key** field — it is stored in `UserDefaults` on the device only.

## Project Structure

```
CVTailor/
├── Models/
│   └── AppModel.swift          # @Observable state — drives the entire UI
├── Services/
│   ├── AnthropicService.swift  # URLSession call to POST /v1/messages
│   └── PDFService.swift        # PDFKit parsing, CoreText PDF generation, Transferable export types
└── Views/
    ├── InputView.swift         # API key, job description, CV input, loading overlay
    └── ResultView.swift        # Scrollable result, PDF + TXT export via ShareLink
```

## Usage

1. Paste your **Anthropic API key** into the key field.
2. Paste the **job description** into the Job Description field.
3. Enter your **CV** by typing/pasting in the text editor, or tap **Import PDF** to pick a PDF file.
4. Tap **Tailor My CV** — a loading overlay appears while the model processes the request.
5. The tailored CV appears on the next screen. Use the toolbar buttons to **export as PDF** or **export as TXT**.
6. To start over, tap the **trash icon** in the top-right corner and confirm the prompt.

## Notes

- The API key is stored in `UserDefaults`. For a production release, move it to the Keychain.
- Image-based or scanned PDFs cannot have text extracted and will show an error.
- The model used is `claude-opus-4-7`. Swap to a smaller model in `AnthropicService.swift` to reduce cost.
- PDF format matching works on text-based PDFs. The style guide is sampled from the first page: most-frequent font size = body, largest = name, the size in between = section headers.
