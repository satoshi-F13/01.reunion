# AI-Powered Chat App with Claude

A Shiny application that uses Claude AI to answer questions based on stored markdown documents and datasets (CSV/RDS files).

## Features

- 🤖 **Claude AI Integration**: Uses Claude Sonnet 4 for intelligent responses
- 📄 **Document Search**: Searches through markdown files
- 📊 **Dataset Analysis**: Analyzes CSV and RDS datasets
- 🌍 **Multi-language Support**: English, Japanese, and Italian
- 💬 **Chat Interface**: Clean, interactive chat UI using `shinychat`

## Prerequisites

### Required R Packages

```r
install.packages(c(
  "shiny",
  "tidyverse",
  "shinychat",
  "httr",
  "jsonlite",
  "bslib"
))
```

### Claude API Key

You need an Anthropic API key to use this app. Get one at: https://console.anthropic.com/

## Setup Instructions

### 1. Set Up API Key

**Option A: Environment Variable (Recommended)**
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

**Option B: .Renviron File**
Create or edit `~/.Renviron`:
```
ANTHROPIC_API_KEY=your-api-key-here
```

### 2. Prepare Your Data

The app looks for data in two directories:

```
app.R
data/
  ├── markdown/     # Place your .md files here
  └── datasets/     # Place your .csv or .rds files here
```

**Sample files are already included:**
- `data/markdown/product_info.md` - Sample product documentation
- `data/datasets/customers.csv` - Sample customer data

### 3. Add Your Own Data

**Markdown Files:**
```bash
# Add any markdown documentation
cp your_document.md data/markdown/
```

**CSV Datasets:**
```bash
# Add CSV files
cp your_data.csv data/datasets/
```

**RDS Datasets:**
```r
# Save R data frames as RDS
saveRDS(your_dataframe, "data/datasets/your_data.rds")
```

## Running the App

### From RStudio
1. Open `app.R`
2. Click "Run App" button

### From Command Line
```bash
R -e "shiny::runApp('app.R')"
```

### Specify Port
```r
shiny::runApp('app.R', port = 3838, host = '0.0.0.0')
```

## Usage Guide

### 1. Launch the App
After starting, you'll see:
- Left sidebar: Settings and knowledge base status
- Main panel: Chat interface

### 2. Select Language
Choose your preferred response language:
- English (default)
- Japanese (日本語)
- Italian (Italiano)

### 3. Check Knowledge Base Status
The sidebar shows:
- Number of markdown files loaded
- Number of datasets loaded
- Last update time

### 4. Ask Questions

**Example Questions:**

*About Documents:*
- "What products do you offer?"
- "What are the pricing plans?"
- "What are your support hours?"

*About Datasets:*
- "How many customers do we have?"
- "Which customers are on the Enterprise plan?"
- "What's our total monthly revenue?"
- "Show me customers who signed up in 2024"

*Multi-language:*
- 🇯🇵 "製品について教えてください" (Tell me about the products)
- 🇮🇹 "Quali sono i piani tariffari?" (What are the pricing plans?)

### 5. Reload Data
After adding new files:
1. Click "Reload Data" button
2. Wait for success notification
3. Continue chatting with updated knowledge base

## Workflow

```
User Question
     ↓
Claude searches markdown files & datasets
     ↓
AI analyzes and finds relevant information
     ↓
Short, accurate response in selected language
```

## File Structure

```
.
├── app.R                          # Main Shiny application
├── README.md                      # This file
├── data/
│   ├── markdown/
│   │   └── product_info.md       # Sample markdown
│   └── datasets/
│       └── customers.csv          # Sample dataset
└── .Renviron                      # API key (create this)
```

## Troubleshooting

### "ANTHROPIC_API_KEY not set"
- Make sure you've set the environment variable
- Restart R/RStudio after setting .Renviron
- Check: `Sys.getenv("ANTHROPIC_API_KEY")`

### "No knowledge base found"
- Ensure files are in correct directories
- Click "Reload Data" button
- Check file permissions

### "API Error"
- Verify API key is valid
- Check internet connection
- Ensure you have API credits

### Package Installation Issues
```r
# If shinychat isn't available from CRAN:
install.packages("remotes")
remotes::install_github("jcheng5/shinychat")
```

## Customization

### Add More Languages
Edit the `language_instructions` in `call_claude()` function:

```r
language_instructions <- switch(language,
  "English" = "Respond in English.",
  "Japanese" = "日本語で回答してください。",
  "Italian" = "Rispondi in italiano.",
  "Spanish" = "Responde en español.",  # Add new language
  "Respond in English."
)
```

### Adjust Response Length
Modify `max_tokens` in the API call:

```r
body <- list(
  model = "claude-sonnet-4-20250514",
  max_tokens = 2048,  # Increase for longer responses
  ...
)
```

### Change Theme
Modify the `bs_theme()` in UI:

```r
theme = bslib::bs_theme(version = 5, bootswatch = "darkly")
```

Available themes: cosmo, flatly, darkly, superhero, etc.

## API Costs

Claude Sonnet 4 pricing (as of Dec 2024):
- Input: ~$3 per million tokens
- Output: ~$15 per million tokens

Typical chat message costs < $0.01

## Security Notes

- **Never commit .Renviron** with API keys to version control
- Add `.Renviron` to `.gitignore`
- Use environment variables in production
- Keep API keys secure and private

## References

- [Posit AI Tools](https://posit.co/blog/2025-09-26-ai-newsletter/)
- [Anthropic API Documentation](https://docs.anthropic.com/)
- [shinychat Package](https://github.com/jcheng5/shinychat)

## License

This project is provided as-is for educational and development purposes.

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Anthropic API documentation
3. Check R package documentation

---

**Built with ❤️ using R, Shiny, and Claude AI**
