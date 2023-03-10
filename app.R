# -----------------------------------------------------------------------------
#
# Shiny app to plot MSA results
# Author: Joseph V. Casillas (joseph.casillas@rutgers.edu)
# Last update: 20230105
# About: 
#  - This app loads the MSA dataset and generates two plots: 
#    - Horizontal forest plot of the meta-analytic results
#    - Scatterplot of effect sizes as a function of continuous variables
#
# -----------------------------------------------------------------------------




# Libraries -------------------------------------------------------------------

library("shiny")
library("ggplot2")
library("dplyr")
library("glue")
library("forcats")
library("stringr")
library("Cairo")

# -----------------------------------------------------------------------------




# Setup -----------------------------------------------------------------------

# This improves how ggplot is rendered in shiny apps
options(shiny.usecairo = T)

# Load data, relevel model id, and prep color_var labels
merged <- readRDS("merged_posterior_shiny.rds") %>%
  mutate(
    model_id = fct_reorder(model_id, post_mean),
    compelling = if_else(
      compelling == "not compelling",
      true = "Not compelling",
      false = "Compelling"
      ), 
    found_effect = str_to_sentence(found_effect), 
    outcome = str_to_title(outcome),
    temporal_window = str_to_sentence(temporal_window),
    operationalisation = str_to_sentence(operationalisation),
    typicality = str_to_sentence(typicality)
  )

# Set MSA theme for forest plot
msa_theme <- function() {
  list(
    theme_classic(base_size = 20),
    theme(
      legend.position = c(1, 0), 
      legend.direction = "horizontal", 
      legend.background = element_rect(fill = alpha("white", 0)), 
      legend.justification = c("right", "bottom"),
      legend.box.just = "right",
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      axis.line = element_blank()
    ),
    guides(
      color = guide_legend(
        ncol = 4, 
        override.aes = list(size = 6, pch = 20, alpha = 1)
      )
    )
  )
}

# Set MSA theme for scatterplot
msa_scatter_theme <- function() {
  list(
    theme_minimal(base_size = 20),
    theme(
      legend.position = c(0, 1),
      legend.direction = "horizontal", 
      legend.justification = c("left", "top"),
      legend.box.just = "left",
      axis.title.y = element_text(size = rel(.9), hjust = 0.95),
      axis.title.x = element_text(size = rel(.9), hjust = 0.95),
      panel.grid.major = element_line(colour = 'grey90', linewidth = 0.15),
      panel.grid.minor = element_line(colour = 'grey90', linewidth = 0.15)
    ),
    guides(color = guide_legend(
      ncol = 4, 
      override.aes = list(size = 5, alpha = 1)
      )
    )
  )
}

# -----------------------------------------------------------------------------




# Shiny UI --------------------------------------------------------------------

# Setup fluid page with fixed navbar and three panels
ui <- navbarPage(
  # Include MSA logo in navbar
  title = div(img(src = "logo.png", height = 50, style = "margin-top:-20px")),
  fluid = T, windowTitle = "MSA",
  # Add some CSS to fix padding in navbar
  header = tags$head(
    tags$style(
      HTML(
       '.navbar-default .navbar-nav > .active {background-color:white;}
        .navbar-default .navbar-nav > .active > a {background-color: white;}
        .navbar-default .navbar-nav > .active > a:hover {background-color: white;}
        .navbar-default .navbar-nav > .active > a:focus,
        .navbar-default .navbar-nav > li > a:hover {
           color:black;
           background-color:white;
           text-decoration
        }
        .navbar {
          background-color: #fff;
          min-height:60px !important;
          padding-top:20px !important;
          padding-bottom:10px !important;
        }'
      )
    )
  ),
  # Tab panel 1: Description of the app
  tabPanel("Overview",
    fluidRow(
      column(2, p("")),
      column(8,
        h1("Welcome to the MSA shiny app"), 
        div(align = "center", 
          img(src = "ForkingPaths.png", width = "50%", 
              style = "float:right; padding-left:10px"
             )
        ),
        #div(align = "center", 
        #  h5("Do speakers acoustically modify utterances to signal 
        #   atypical word combinations?")),
        p("We gave the same speech production data set to 46 teams of 
           researchers and asked them to answer the same research 
           question:", 
        strong("Do speakers acoustically modify utterances to signal
           atypical word combinations?"),
           "Using this shiny app you can explore parts of the data set."),
        p("Upon receiving the data set, each team of analysts 
           decided how to takle the research question, from choosing which 
           phonetic measurements or other type of data to obtain from the 
           recordings, to how to statistically analyze them. Next, they 
           submitted a report of their findings and reviewed those other 
           teams. Finally, we (the project coordinators) aggregated all of 
           the individual analyses together using advanced meta-analytic 
           techniques."),
        p("The figure you see here illustrates some of the analytic 
           flexibility associated with acoustic analyses. (A) An example of 
           multiple possible and justifiable decisions when comparing two 
           utterances; (B) Waveform and f0 track of the utterances", 
        em("'I can't bear ANOTHER meeting on Zoom'"), 
           "and", 
        em("'I can't bear another meeting on ZOOM'."), 
           "The green boxes mark the word 'another' in both sentences; (C)
           Spectrogram and f0 track of the word 'another', exemplifying 
           possible operationalizations of differences in f0."), 
        p("The registered report, entitled ",
        strong("Multidimensional signals and analytic flexibility: Estimating 
           degrees of freedom in human speech analyses"), 
           "is accepted for publication in AMPPS and will appear soon.
           In the meantime, you can learn more about the MSA project at the 
           project website", 
           tags$a("(https://many-speech-analyses.github.io)", href = "https://many-speech-analyses.github.io"), 
           "and you can read the preprint here:", 
           tags$a("https://psyarxiv.com/q8t2k/.", href = "https://psyarxiv.com/q8t2k/"))
      ),
      column(2, p(""))
    ),
    # Include footer with author info and github links
    br(), br(), br(),
    fluidRow(
      column(2, p("")),
      column(8,
        wellPanel(
          p(strong("Initiating authors:"), 
            tags$a("Stefano Coretta,", href = "https://stefanocoretta.github.io"), 
            tags$a("Joseph V. Casillas,", href = "https://www.jvcasillas.com"), "and", 
            tags$a("Timo Roettger", href = "https://www.simplpoints.com"),
            br(),
            strong("Shiny app created by:"),
            "Joseph V. Casillas",
            br(),
            strong("Source code:"),
            tags$a("Github", href = "https://github.com/jvcasillas/msa/"), 
            br(),
            strong("Problems?"), 
            tags$a("Submit an issue", href = "https://github.com/jvcasillas/msa/issues")
          )
        )
      ),
      column(2, p(""))
    )
  ),
  # Panel 2: Forest plot of meta-analytic estimates
  tabPanel("Outcomes",
    fluidRow(
      # Spacer left
      column(2, p("")),
      # color_var dropdown
      column(3,
        div(align = "left",
          selectInput(
            inputId = "color",
            label = "Choose a factor:",
            choices = c(
              "Outcome measure" = "outcome",
              "Temporal window" = "temporal_window",
              "Operationalization" = "operationalisation",
              "Typicality" = "typicality", 
              "Found effect?" = "found_effect"
            )
          )
        )
      ),
      # Framework dropdown
      column(3,
        div(align = "left",
          selectInput(
            inputId = "framework",
            label = "Inferential framework:",
            choices = c("Any", "Frequentist", "Bayesian")
          )
        )
      ),
      # Plot adjustment checkboxes
      column(3,
        div(align = "left",
          checkboxInput(
            inputId = "include_submitted",
            label = "Plot submitted effect",
            value = TRUE
          ),
          checkboxInput(
            inputId = "hide_intervals",
            label = "Hide CIs",
            value = FALSE
          )
        )
      ),
      # Spacer right
      column(1, p(""))
    ),
    fluidRow(
      column(2, p("")), 
      column(8, uiOutput("checkbox")), 
      column(2, p("")),
    ),
    # Generate plot
    fluidRow(
      column(1, p("")), # Spacer left
      column(10,
        div(align = "center",
          plotOutput("postPlot", width = "100%", height = "500px")
        )
      ),
      column(1, p("")) # Spacer right
    )
  ),
  # Panel 3: scatterplot
  tabPanel("Scatterplots",
    fluidRow(
      # Spacer left
      column(2, p("")),
      # Outcome dropdown
      column(2,
        selectInput(
          inputId = "sp_y_var",
          label = "Choose effect",
          choices = c(
            "Meta-analytic effect" = "post_mean",
            "Submitted effect" = "estimate"
          )
        )
      ),
      # Predictor dropdown
      column(3,
        selectInput(
          inputId = "sp_x_var",
          label = "Choose x variable",
          choices = c(
            "Years after PhD" = "years_from_phd",
            "Prior belief" = "prior_belief",
            "Peer rating (acoustic analysis)" = "phon_rating",
            "Peer rating (statistical analysis)" = "stat_rating",
            "Peer rating (overall)" = "all_rating"
          )
        )
      ),
      # color_var dropdown
      column(2,
        selectInput(
          inputId = "sp_color_var",
          label = "Choose factor",
          choices = c(
            "None" = "none",
            "Outcome measure" = "outcome",
            "Temporal window" = "temporal_window",
            "Operationalization" = "operationalisation",
            "Typicality" = "typicality", 
            "Found effect?" = "found_effect"
          )
        )
      ),
      # Plot adjustment checkboxes
      column(3,
        div(align = "left",
          checkboxInput(
            inputId = "std_vars",
            label = "Standardize predictor",
            value = FALSE
          ),
          checkboxInput(
            inputId = "add_regression",
            label = "Add regression line",
            value = FALSE
          )
        )
      )
    ),
    # Generate plot
    fluidRow(
      column(1, p("")), # Spacer left
      column(10,
        div(align = "center",
          plotOutput("scatterPlot", width = "100%", height = "500px")
        )
      ),
      column(1, p("")) # Spacer right
    )
  )
)

# -----------------------------------------------------------------------------




# Shiny server ----------------------------------------------------------------

# Define server logic required to generate plots
server <- function(input, output) {

  # Generate checkboxes for UI
  output$checkbox <- renderUI({
    choice <- select(merged, input$color) %>% 
      na.omit() %>% 
      pull(input$color) %>% 
      unique()
    
    checkboxGroupInput(
      inputId = "checkbox", 
      label = NULL, 
      choices = choice, 
      selected = choice, 
      inline = T
    )
    
  })

  # Select subset of `merged` dataframe
  data_post <- reactive({

    if (input$framework == 'Any') {
      # All data
      merged %>%
        select(post_mean, model_id, estimate, se, lower95, higher95,
               color_var = input$color) %>%
        filter(!is.na(color_var), color_var %in% input$checkbox)

    } else if (input$framework == 'Frequentist') {
      # Frequentist models
      merged %>%
        filter(framework == "frequentist") %>%
        select(post_mean, model_id, estimate, se, lower95, higher95,
               color_var = input$color) %>%
        filter(!is.na(color_var), color_var %in% input$checkbox)

    } else {
      # Bayesian models
      merged %>%
        filter(framework == "bayesian") %>%
        select(post_mean, model_id, estimate, se, lower95, higher95,
               color_var = input$color) %>%
        filter(!is.na(color_var), color_var %in% input$checkbox)

    }
  })

  # Select point size based on number of points to plot
  # The higher the number of points, the smaller the point size
  point_size <- reactive({
    2.90 - (nrow(data_post()) / 100)
  })

  # Select line width based on number of points to plot
  # The higher the number of points, the thinner the line width
  line_size <- reactive({
    2.75 - (nrow(data_post()) / 100)
  })

  # Select stroke thickness based on number of points to plot
  # The higher the number of points, the thinner the stroke
  stroke_size <- reactive({
    2.50 - (nrow(data_post()) / 100)
  })

  # Reactive x-label based on models to plot
  x_lab <- reactive({
    if (input$framework == "Any") {
      "All models"
    } else if (input$framework == "Frequentist") {
      "Frequentist models"
    } else {
      "Bayesian models"
    }
  })

  # Shorten figure caption
  fig_capl1 <- "Posterior estimates from meta-analytic model (color),\n"
  fig_capl2 <- "and raw estimates extracted from teams' models (grey)\n"

  # Generate plot
  output$postPlot <- renderPlot({

    if (input$include_submitted == TRUE) {
      if (input$hide_intervals == TRUE) {
        # Include submitted, omit intervals
        ggplot(data_post()) +
        aes(x = model_id, y = post_mean) +
        geom_hline(yintercept = 0, lty = 3, alpha = 0.5) +
        geom_point(aes(y = estimate), pch = 17, alpha = 0.2, size = point_size()) +
        geom_point(aes(color = color_var), show.legend = T,
          size = point_size(), pch = 21, stroke = line_size()) +
        scale_x_discrete(expand =  c(0.01,0.01)) +
        labs(caption = glue("{fig_capl1}{fig_capl2}"),
          x = x_lab(),
          y = "Posterior effect size") +
        scale_color_viridis_d(name = NULL, begin = 0.15, end = 0.85) +
        msa_theme()

      } else {
        # Include submitted, include intervals
        ggplot(data_post()) +
        aes(x = model_id, y = post_mean) +
        geom_hline(yintercept = 0, lty = 3, alpha = 0.5) +
        geom_segment(lineend = "round", linewidth = line_size(), alpha = 0.1,
          aes(xend = model_id, y = estimate-1.96*se, yend = estimate+1.96*se)) +
        geom_point(aes(y = estimate), pch = 17, alpha = 0.2, size = point_size()) +
        geom_segment(lineend = "round", linewidth = line_size(),
          alpha = 0.5, show.legend = F,
          aes(y = lower95, yend = higher95, xend = model_id, color = color_var)) +
        geom_point(aes(color = color_var), show.legend = T,
          size = point_size(), pch = 21, stroke = line_size()) +
        scale_x_discrete(expand =  c(0.01,0.01)) +
        labs(caption = glue("{fig_capl1}{fig_capl2}"),
          x = x_lab(),
          y = "Posterior effect size") +
        scale_color_viridis_d(name = NULL, begin = 0.15, end = 0.85) +
        msa_theme()

      }
    } else {
      if (input$hide_intervals == TRUE) {
        # Omit submitted, omit intervals
        ggplot(data_post()) +
        aes(x = model_id, y = post_mean) +
        geom_hline(yintercept = 0, lty = 3, alpha = 0.5) +
        geom_point(aes(color = color_var),
          size = point_size(), show.legend = T, pch = 21, stroke = line_size()) +
        scale_x_discrete(expand =  c(0.01,0.01)) +
        labs(x = x_lab(), y = "Posterior effect size") +
        scale_color_viridis_d(name = NULL, begin = 0.15, end = 0.85) +
        msa_theme()
      } else {
        # Omit submitted, include intervals
        ggplot(data_post()) +
        aes(x = model_id, y = post_mean) +
        geom_hline(yintercept = 0, lty = 3, alpha = 0.5) +
        geom_segment(lineend = "round", linewidth = line_size(), 
          alpha = 0.5, show.legend = F, 
          aes(y = lower95, yend = higher95, xend = model_id, color = color_var)) +
        geom_point(aes(color = color_var),
          size = point_size(), pch = 21, stroke = line_size()) +
        scale_x_discrete(expand =  c(0.01,0.01)) +
        labs(x = x_lab(), y = "Posterior effect size") +
        scale_color_viridis_d(name = NULL, begin = 0.15, end = 0.85) +
        msa_theme()
      }
    }
  })

  # Select subset of `merged` dataframe
  data_scatter <- reactive({

    if (input$std_vars == FALSE) {
      if (input$sp_color_var == "none") {
        # Raw xvar, omit color var
        merged %>%
          select(y = input$sp_y_var, x = input$sp_x_var) %>% 
          na.omit()

      } else {
        # Raw xvar, include color var
        merged %>%
          select(y = input$sp_y_var, x = input$sp_x_var,
                 color_var = input$sp_color_var) %>%
          filter(!is.na(color_var))

      }
    } else {
      if (input$sp_color_var == "none") {
        # Standardize xvar, omit color var
        merged %>%
          select(y = input$sp_y_var, x = input$sp_x_var) %>%
          mutate(x = (x - mean(x, na.rm = T)) / sd(x, na.rm = T)) %>% 
          na.omit()

      } else {
        # Standardize xvar, include color var
        merged %>%
          select(y = input$sp_y_var, x = input$sp_x_var,
                 color_var = input$sp_color_var) %>%
          filter(!is.na(color_var)) %>%
          mutate(x = (x - mean(x, na.rm = T)) / sd(x, na.rm = T)) %>% 
          na.omit()

      }
    }
  })

  # Get y-lab and make it pretty
  sp_y_lab <- reactive({
    if (input$sp_y_var == "post_mean") {
      "Meta-analytic effect"
    } else {
      "Submitted effect"
    }
  })

  # Get x-lab and make it pretty
  sp_x_lab <- reactive({
    if (input$sp_x_var == "years_from_phd") {
      "Years after PhD"
    } else if (input$sp_x_var == "prior_belief") {
      "Prior belief"
    } else if (input$sp_x_var == "phon_rating") {
      "Peer rating\n(acoustic analysis)"
    } else if (input$sp_x_var == "stat_rating") {
      "Peer rating\n(statistical analysis)"
    } else {
      "Peer rating\n(overall)"
    }
  })

  # Generate plot
  output$scatterPlot <- renderPlot({

    if (input$add_regression == FALSE) {
      if (input$sp_color_var == "none") {
        # Omit regression line, omit color var
        ggplot(data_scatter()) +
        aes(x = x, y = y) +
        geom_point(alpha = 0.3, size = 4) +
        labs(y = sp_y_lab(), x = sp_x_lab()) +
        msa_scatter_theme()

      } else {
        # Omit regression line, include color var
        ggplot(data_scatter()) +
        aes(x = x, y = y, color = color_var) +
        geom_point(alpha = 0.3, size = 4) +
        labs(y = sp_y_lab(), x = sp_x_lab()) +
        scale_color_viridis_d(name = NULL, begin = 0.15, end = 0.85) +
        msa_scatter_theme()

      }
    } else {
      if (input$sp_color_var == "none") {
        # Include regression line, omit color var
        ggplot(data_scatter()) +
        aes(x = x, y = y) +
        geom_point(alpha = 0.3, size = 4) +
        geom_smooth(method = "lm", formula = "y ~ x", linewidth = 1, se = F) +
        labs(y = sp_y_lab(), x = sp_x_lab()) +
        msa_scatter_theme()

      } else {
        # Include regression line, include color var
        ggplot(data_scatter()) +
        aes(x = x, y = y, color = color_var) +
        geom_smooth(method = "lm", formula = "y ~ x", linewidth = 1, 
          fullrange = T, show.legend = F, alpha = 0.2, se = F) +
        geom_point(alpha = 0.3, size = 4) +
        labs(y = sp_y_lab(), x = sp_x_lab()) +
        scale_color_viridis_d(name = NULL, begin = 0.15, end = 0.85) +
        msa_scatter_theme()

      }
    }
  })
}

# Run the app
shinyApp(ui = ui, server = server)
