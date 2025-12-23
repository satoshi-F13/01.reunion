# AI-Powered Chat App with Claude - Enhanced with Custom Personalities
# Using shinychat package (v0.3.0+)
# Required packages
library(shiny)
library(tidyverse)
library(shinychat)
library(httr)
library(jsonlite)
library(bslib)

# Configuration
ANTHROPIC_API_KEY <- Sys.getenv("ANTHROPIC_API_KEY")
if (ANTHROPIC_API_KEY == "") {
  warning(
    "ANTHROPIC_API_KEY not set. Please set it in .Renviron or as environment variable"
  )
}

# Data directory paths
DATA_DIR <- "data"
MARKDOWN_DIR <- file.path(DATA_DIR, "markdown")
DATASET_DIR <- file.path(DATA_DIR, "datasets")

# Create directories if they don't exist
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(MARKDOWN_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(DATASET_DIR, showWarnings = FALSE, recursive = TRUE)

# Function to load all markdown files
load_markdown_files <- function() {
  md_files <- list.files(MARKDOWN_DIR, pattern = "\\.md$", full.names = TRUE)

  if (length(md_files) == 0) {
    return(NULL)
  }

  md_content <- map_chr(md_files, function(file) {
    content <- read_file(file)
    filename <- basename(file)
    paste0("=== Document: ", filename, " ===\n\n", content, "\n\n")
  })

  paste(md_content, collapse = "\n---\n\n")
}

# Function to load all datasets (CSV and RDS)
load_datasets <- function() {
  csv_files <- list.files(DATASET_DIR, pattern = "\\.csv$", full.names = TRUE)
  rds_files <- list.files(DATASET_DIR, pattern = "\\.rds$", full.names = TRUE)

  datasets_info <- list()

  # Load CSV files
  for (file in csv_files) {
    tryCatch(
      {
        data <- read_csv(file, show_col_types = FALSE)
        filename <- basename(file)

        # Create summary
        summary_text <- paste0(
          "Dataset: ",
          filename,
          "\n",
          "Rows: ",
          nrow(data),
          ", Columns: ",
          ncol(data),
          "\n",
          "Column names: ",
          paste(names(data), collapse = ", "),
          "\n",
          "Sample data (first 5 rows):\n",
          paste(capture.output(print(head(data, 5))), collapse = "\n")
        )

        datasets_info[[filename]] <- list(data = data, summary = summary_text)
      },
      error = function(e) {
        warning(paste("Error loading", file, ":", e$message))
      }
    )
  }

  # Load RDS files
  for (file in rds_files) {
    tryCatch(
      {
        data <- readRDS(file)
        filename <- basename(file)

        if (is.data.frame(data)) {
          summary_text <- paste0(
            "Dataset: ",
            filename,
            "\n",
            "Rows: ",
            nrow(data),
            ", Columns: ",
            ncol(data),
            "\n",
            "Column names: ",
            paste(names(data), collapse = ", "),
            "\n",
            "Sample data (first 5 rows):\n",
            paste(capture.output(print(head(data, 5))), collapse = "\n")
          )

          datasets_info[[filename]] <- list(data = data, summary = summary_text)
        }
      },
      error = function(e) {
        warning(paste("Error loading", file, ":", e$message))
      }
    )
  }

  datasets_info
}

# Function to create knowledge base context
create_context <- function(markdown_content, datasets_info) {
  context_parts <- list()

  if (!is.null(markdown_content)) {
    context_parts <- c(
      context_parts,
      list(
        "=== MARKDOWN DOCUMENTS ===",
        markdown_content
      )
    )
  }

  if (length(datasets_info) > 0) {
    dataset_summaries <- map_chr(datasets_info, ~ .$summary)
    context_parts <- c(
      context_parts,
      list(
        "=== DATASETS INFORMATION ===",
        paste(dataset_summaries, collapse = "\n\n---\n\n")
      )
    )
  }

  paste(context_parts, collapse = "\n\n")
}

# Function to call Claude API with customizable personality
call_claude <- function(user_message, context, language) {
  # ====== CUSTOMIZE AI PERSONALITY HERE ======
  # You can easily modify the tone, catchphrase, and style for each language!

  language_instructions <- switch(
    language,
    "English" = "Respond in English with a friendly and helpful tone.",

    "日本語" = paste0(
      "日本語で回答してください。",
      "カジュアルで親しみやすい口調で話してください。",
      "語尾に「～だぜぇ」とつけることで、口調全体にワイルド感を演出します",
      "「ワイルドだろぉ」という言葉で失敗や残念な状況を表現しつつ、最後は勢いで乗り切るスタイルで回答してください。",
      "具体例：「誰からの質問だい～ワイルドだろぉ」、（質問が繰り返される場合）「戻ってくるパターンかい、この扉。ビビったぜ」 "
    ),

    "Deutsch" = "Auf Deutsch antworten. Sei freundlich und hilfsbereit.",

    "Français" = "Répondez en français avec un ton amical et décontracté.",

    "Español" = "Responder en español con un tono amigable y cercano.",

    "Respond in English."
  )
  # ==========================================

  system_prompt <- paste0(
    "You are a helpful assistant that answers questions based on provided documents and datasets. ",
    "Search through the provided context carefully and give concise, accurate answers. ",
    "If the information is not in the provided context, say so clearly. ",
    language_instructions,
    "\n\n",
    "=== KNOWLEDGE BASE ===\n",
    context
  )

  body <- list(
    model = "claude-sonnet-4-20250514",
    max_tokens = 1024,
    system = system_prompt,
    messages = list(
      list(
        role = "user",
        content = user_message
      )
    )
  )

  response <- POST(
    url = "https://api.anthropic.com/v1/messages",
    add_headers(
      "x-api-key" = ANTHROPIC_API_KEY,
      "anthropic-version" = "2023-06-01",
      "content-type" = "application/json"
    ),
    body = toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )

  if (status_code(response) != 200) {
    error_content <- content(response, "text", encoding = "UTF-8")
    stop("API Error: ", error_content)
  }

  result <- content(response, "parsed")
  result$content[[1]]$text
}

# UI
ui <- page_fillable(
  theme = bs_theme(version = 5, bootswatch = "flatly"),

  # Title and description
  div(
    style = "padding: 20px; background-color: #f8f9fa; border-bottom: 1px solid #dee2e6;",
    h2("g-AI-go チャットボット"),
    p(
      "37期同窓会について適度に聞いてみてね！",
      style = "margin-bottom: 0;"
    )
  ),

  layout_sidebar(
    sidebar = sidebar(
      width = 300,

      h4("せってい"),

      selectInput(
        "language",
        "たいおーげんご:",
        choices = c("English", "日本語", "Deutsch", "Français", "Español"),
        selected = "日本語"
      ),

      hr(),

      h4("でーたべーす"),

      verbatimTextOutput("kb_status"),

      hr(),

      actionButton(
        "reload_data",
        "りろーど",
        class = "btn-primary",
        width = "100%"
      ),

      hr(),

      h5("つかいかた"),
      tags$small(
        # "1. Place markdown files in: data/markdown/",
        # br(),
        # "2. Place CSV/RDS files in: data/datasets/",
        # br(),
        # "3. Click 'りろーど' after adding files",
        # br(),
        "ことばをえらんで、きいてみてね"
      )
    ),

    # Main chat interface
    chat_ui(
      "chat",
      messages = "**ハロー!** AIチャットボットのgAIgoだよ。同窓会について何か聞きたいことある？",
      fill = TRUE
    )
  )
)

# Server
server <- function(input, output, session) {
  # Reactive values to store knowledge base
  kb <- reactiveValues(
    markdown = NULL,
    datasets = NULL,
    context = NULL,
    last_updated = NULL
  )

  # Load data on startup
  observe({
    kb$markdown <- load_markdown_files()
    kb$datasets <- load_datasets()
    kb$context <- create_context(kb$markdown, kb$datasets)
    kb$last_updated <- Sys.time()
  })

  # りろーど when button is clicked
  observeEvent(input$reload_data, {
    showNotification(
      "よみこみちゅう...",
      type = "message",
      duration = 2
    )

    kb$markdown <- load_markdown_files()
    kb$datasets <- load_datasets()
    kb$context <- create_context(kb$markdown, kb$datasets)
    kb$last_updated <- Sys.time()

    showNotification(
      "Knowledge base reloaded successfully!",
      type = "success",
      duration = 3
    )
  })

  # Display knowledge base status
  output$kb_status <- renderText({
    md_count <- if (!is.null(kb$markdown)) {
      length(list.files(MARKDOWN_DIR, pattern = "\\.md$"))
    } else {
      0
    }

    ds_count <- if (!is.null(kb$datasets)) {
      length(kb$datasets)
    } else {
      0
    }

    paste0(
      "Markdown files: ",
      md_count,
      "\n",
      "Datasets: ",
      ds_count,
      "\n",
      "Last updated: ",
      if (!is.null(kb$last_updated)) {
        format(kb$last_updated, "%H:%M:%S")
      } else {
        "Never"
      }
    )
  })

  # Handle chat user input
  observeEvent(input$chat_user_input, {
    user_message <- input$chat_user_input

    # Check if knowledge base is empty
    if (is.null(kb$context) || nchar(kb$context) < 10) {
      response <- "Please add markdown files or datasets to the data directories and click 'りろーど'."
      chat_append("chat", response)
      return()
    }

    # Check API key
    if (ANTHROPIC_API_KEY == "") {
      response <- "Error: ANTHROPIC_API_KEY not set. Please configure your API key in .Renviron file."
      chat_append("chat", response)
      return()
    }

    # Call Claude API
    tryCatch(
      {
        response <- call_claude(user_message, kb$context, input$language)
        chat_append("chat", response)
      },
      error = function(e) {
        error_msg <- paste("Error:", e$message)
        chat_append("chat", error_msg)
      }
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)
