# Quick Start Guide

## 🚀 Get Started in 3 Minutes

### Step 1: Install Required Packages

Open R or RStudio and run:

```r
# Install required packages
install.packages(c(
  "shiny",
  "tidyverse",
  "httr",
  "jsonlite",
  "bslib"
))
```

### Step 2: Set Your API Key

**Get API Key:**
1. Go to https://console.anthropic.com/
2. Sign up or log in
3. Create an API key
4. Copy the key (starts with "sk-ant-...")

**Set API Key:**

Create a file named `.Renviron` in your project folder:
```
ANTHROPIC_API_KEY=sk-ant-api03-your-actual-key-here
```

**Or set it temporarily in R:**
```r
Sys.setenv(ANTHROPIC_API_KEY = "sk-ant-api03-your-actual-key-here")
```

### Step 3: Run the App

```r
# Open the simple version (no extra dependencies)
shiny::runApp("app_simple.R")

# OR open the full version (requires shinychat package)
# install.packages("remotes")
# remotes::install_github("jcheng5/shinychat")
# shiny::runApp("app.R")
```

## 📝 Try These Example Questions

Once the app is running, try asking:

**English:**
- "What products do you offer?"
- "How much does DataPro Enterprise cost?"
- "How many customers do we have?"
- "Which customers are on trial?"
- "What's our total monthly revenue?"

**Japanese (日本語):**
- "どんな製品がありますか？" (What products are available?)
- "価格プランを教えてください" (Tell me about pricing plans)
- "サポート時間は？" (What are support hours?)

**Italian (Italiano):**
- "Quali prodotti offrite?" (What products do you offer?)
- "Quanto costa DataPro Enterprise?" (How much does DataPro Enterprise cost?)
- "Quali integrazioni sono disponibili?" (What integrations are available?)

## 📁 Add Your Own Data

### Add Markdown Documents:
```bash
# Just copy your .md files to the markdown folder
cp my_document.md data/markdown/
```

### Add CSV Data:
```bash
# Copy CSV files to datasets folder
cp my_data.csv data/datasets/
```

### Add R Data:
```r
# Save your R data frame
my_data <- data.frame(
  id = 1:5,
  name = c("A", "B", "C", "D", "E"),
  value = c(10, 20, 30, 40, 50)
)
saveRDS(my_data, "data/datasets/my_data.rds")
```

After adding files, click **"Reload Data"** in the app!

## 🎨 Choose Your Version

### `app_simple.R` (Recommended for beginners)
✅ Only needs basic R packages  
✅ Simple setup  
✅ All core features included  

### `app.R` (Advanced)
✅ Better chat UI with shinychat  
✅ More polished interface  
❗ Requires additional package installation  

## ⚠️ Troubleshooting

**"ANTHROPIC_API_KEY not set"**
- Restart R after creating .Renviron
- Check: `Sys.getenv("ANTHROPIC_API_KEY")`
- Make sure there are no spaces around the = sign

**"Package not found"**
- Run: `install.packages("package_name")`
- For shinychat: `remotes::install_github("jcheng5/shinychat")`

**"No knowledge base found"**
- Make sure files are in data/markdown/ or data/datasets/
- Click "Reload Data" button
- Check file extensions (.md, .csv, .rds)

## 💰 API Costs

Each chat costs approximately **$0.001 - $0.01** (less than 1 cent per message)

Monitor your usage at: https://console.anthropic.com/

## 🎉 You're Ready!

Your AI-powered chat assistant is now ready to answer questions based on your documents and data!

---

**Need Help?**
- Check README.md for detailed documentation
- Review sample data in data/ folders
- Test with provided examples first
