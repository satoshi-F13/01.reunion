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
