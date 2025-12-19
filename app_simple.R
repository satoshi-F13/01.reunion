# AI-Powered Chat App with Claude (Simple Version)
# This version doesn't require shinychat package
# Required packages: shiny, tidyverse, httr, jsonlite, bslib

library(shiny)
library(tidyverse)
library(httr)
library(jsonlite)
library(bslib)

# Configuration
ANTHROPIC_API_KEY <- Sys.getenv("ANTHROPIC_API_KEY")
if (ANTHROPIC_API_KEY == "") {
  warning("ANTHROPIC_API_KEY not set. Please set it in .Renviron or as environment variable")
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
    tryCatch({
      data <- read_csv(file, show_col_types = FALSE)
      filename <- basename(file)
      
      # Create summary
      summary_text <- paste0(
        "Dataset: ", filename, "\n",
        "Rows: ", nrow(data), ", Columns: ", ncol(data), "\n",
        "Column names: ", paste(names(data), collapse = ", "), "\n",
        "Sample data (first 5 rows):\n",
        paste(capture.output(print(head(data, 5))), collapse = "\n")
      )
      
      datasets_info[[filename]] <- list(data = data, summary = summary_text)
    }, error = function(e) {
      warning(paste("Error loading", file, ":", e$message))
    })
  }
  
  # Load RDS files
  for (file in rds_files) {
    tryCatch({
      data <- readRDS(file)
      filename <- basename(file)
      
      if (is.data.frame(data)) {
        summary_text <- paste0(
          "Dataset: ", filename, "\n",
          "Rows: ", nrow(data), ", Columns: ", ncol(data), "\n",
          "Column names: ", paste(names(data), collapse = ", "), "\n",
          "Sample data (first 5 rows):\n",
          paste(capture.output(print(head(data, 5))), collapse = "\n")
        )
        
        datasets_info[[filename]] <- list(data = data, summary = summary_text)
      }
    }, error = function(e) {
      warning(paste("Error loading", file, ":", e$message))
    })
  }
  
  datasets_info
}

# Function to create knowledge base context
create_context <- function(markdown_content, datasets_info) {
  context_parts <- list()
  
  if (!is.null(markdown_content)) {
    context_parts <- c(context_parts, list(
      "=== MARKDOWN DOCUMENTS ===",
      markdown_content
    ))
  }
  
  if (length(datasets_info) > 0) {
    dataset_summaries <- map_chr(datasets_info, ~.$summary)
    context_parts <- c(context_parts, list(
      "=== DATASETS INFORMATION ===",
      paste(dataset_summaries, collapse = "\n\n---\n\n")
    ))
  }
  
  paste(context_parts, collapse = "\n\n")
}

# Function to call Claude API
call_claude <- function(user_message, context, language) {
  
  language_instructions <- switch(language,
    "English" = "Respond in English.",
    "Japanese" = "日本語で回答してください。",
    "Italian" = "Rispondi in italiano.",
    "Respond in English."
  )
  
  system_prompt <- paste0(
    "You are a helpful assistant that answers questions based on provided documents and datasets. ",
    "Search through the provided context carefully and give concise, accurate answers. ",
    "If the information is not in the provided context, say so clearly. ",
    language_instructions, "\n\n",
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
    stop("API Error: ", content(response, "text"))
  }
  
  result <- content(response, "parsed")
  result$content[[1]]$text
}

# UI
ui <- fluidPage(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  
  tags$head(
    tags$style(HTML("
      .chat-container {
        height: 600px;
        overflow-y: auto;
        border: 1px solid #ddd;
        border-radius: 8px;
        padding: 15px;
        background-color: #f8f9fa;
        margin-bottom: 15px;
      }
      .message {
        margin-bottom: 15px;
        padding: 10px 15px;
        border-radius: 8px;
        max-width: 80%;
      }
      .user-message {
        background-color: #007bff;
        color: white;
        margin-left: auto;
        text-align: right;
      }
      .assistant-message {
        background-color: white;
        border: 1px solid #ddd;
      }
      .message-label {
        font-weight: bold;
        margin-bottom: 5px;
        font-size: 0.9em;
      }
    "))
  ),
  
  titlePanel("AI Chat Assistant - Document & Dataset Search"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      
      h4("Settings"),
      
      selectInput(
        "language",
        "Response Language:",
        choices = c("English", "Japanese", "Italian"),
        selected = "English"
      ),
      
      hr(),
      
      h4("Knowledge Base Status"),
      
      verbatimTextOutput("kb_status"),
      
      hr(),
      
      actionButton("reload_data", "Reload Data", class = "btn-primary", width = "100%"),
      
      actionButton("clear_chat", "Clear Chat", class = "btn-secondary", width = "100%", 
                   style = "margin-top: 10px;"),
      
      hr(),
      
      h5("Instructions"),
      tags$small(
        "1. Place markdown files in: data/markdown/", br(),
        "2. Place CSV/RDS files in: data/datasets/", br(),
        "3. Click 'Reload Data' after adding files", br(),
        "4. Ask questions in the chat!"
      )
    ),
    
    mainPanel(
      width = 9,
      
      div(
        class = "chat-container",
        uiOutput("chat_history")
      ),
      
      fluidRow(
        column(10,
          textInput("user_input", NULL, placeholder = "Type your question here...", 
                    width = "100%")
        ),
        column(2,
          actionButton("send_btn", "Send", class = "btn-success", width = "100%")
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive values to store knowledge base and chat history
  kb <- reactiveValues(
    markdown = NULL,
    datasets = NULL,
    context = NULL,
    last_updated = NULL
  )
  
  chat <- reactiveValues(
    messages = list()
  )
  
  # Load data on startup
  observe({
    kb$markdown <- load_markdown_files()
    kb$datasets <- load_datasets()
    kb$context <- create_context(kb$markdown, kb$datasets)
    kb$last_updated <- Sys.time()
  })
  
  # Reload data when button is clicked
  observeEvent(input$reload_data, {
    showNotification("Reloading knowledge base...", type = "message")
    
    kb$markdown <- load_markdown_files()
    kb$datasets <- load_datasets()
    kb$context <- create_context(kb$markdown, kb$datasets)
    kb$last_updated <- Sys.time()
    
    showNotification("Knowledge base reloaded successfully!", type = "success")
  })
  
  # Clear chat
  observeEvent(input$clear_chat, {
    chat$messages <- list()
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
      "Markdown files: ", md_count, "\n",
      "Datasets: ", ds_count, "\n",
      "Last updated: ", 
      if (!is.null(kb$last_updated)) format(kb$last_updated, "%H:%M:%S") else "Never"
    )
  })
  
  # Send message on button click or Enter key
  observeEvent(input$send_btn, {
    send_message()
  })
  
  observeEvent(input$user_input, {
    if (nchar(input$user_input) > 0) {
      # Check if Enter was pressed (in reality, we use the button)
      # This is a placeholder for Enter key functionality
    }
  })
  
  send_message <- function() {
    user_msg <- trimws(input$user_input)
    
    if (nchar(user_msg) == 0) {
      return()
    }
    
    # Add user message to chat
    chat$messages <- c(chat$messages, list(
      list(role = "user", content = user_msg, time = Sys.time())
    ))
    
    # Clear input
    updateTextInput(session, "user_input", value = "")
    
    # Check if knowledge base is empty
    if (is.null(kb$context) || nchar(kb$context) < 10) {
      assistant_msg <- "Please add markdown files or datasets to the data directories and reload the knowledge base."
    } else if (ANTHROPIC_API_KEY == "") {
      assistant_msg <- "Error: ANTHROPIC_API_KEY not set. Please configure your API key."
    } else {
      # Call Claude API
      tryCatch({
        assistant_msg <- call_claude(user_msg, kb$context, input$language)
      }, error = function(e) {
        assistant_msg <- paste("Error:", e$message)
      })
    }
    
    # Add assistant response to chat
    chat$messages <- c(chat$messages, list(
      list(role = "assistant", content = assistant_msg, time = Sys.time())
    ))
  }
  
  # Render chat history
  output$chat_history <- renderUI({
    if (length(chat$messages) == 0) {
      return(div(
        style = "text-align: center; color: #999; padding: 50px;",
        h4("Welcome! Ask me anything about your documents and datasets.")
      ))
    }
    
    message_divs <- lapply(chat$messages, function(msg) {
      if (msg$role == "user") {
        div(
          class = "message user-message",
          div(class = "message-label", "You"),
          div(msg$content)
        )
      } else {
        div(
          class = "message assistant-message",
          div(class = "message-label", "Assistant"),
          div(msg$content)
        )
      }
    })
    
    do.call(tagList, message_divs)
  })
}

# Run the application
shinyApp(ui = ui, server = server)
