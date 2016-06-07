library(ggvis)
shinyUI(fluidPage(theme = "style.css",
                  titlePanel("The Rob Schneider Movie Scatter Plot Experience"),
                  fluidRow(
                        column(8,
                               fluidRow(
                                     column(12,
                                            ggvisOutput("scatter")
                                     )
                               ),
                               fluidRow(
                                     column(8,
                                            span(textOutput("mtitle", inline = TRUE), " (", textOutput("myear", inline = TRUE), ")"), br(),
                                            span("Standard Deviation of Ratings: ", textOutput("msd", inline = TRUE)), br(),
                                            span(uiOutput("link", inline = TRUE)),
                                            ggvisOutput("bars")
                                     ),
                                     column(4,
                                            wellPanel(
                                                  span(br(),
                                                       br(),
                                                       tags$span(class="titleText", "Summary Statistics"), br(),
                                                       "Total Movies:",              textOutput("nmovies", inline = TRUE), br(),
                                                       "Public/BoxOffice Correlation:", textOutput("r_ab",    inline = TRUE), br(),
                                                       "Critic/BoxOffice Correlation:", textOutput("r_cb",    inline = TRUE), br(),
                                                       "Public/Critic Correlation:",    textOutput("r_ac",    inline = TRUE)
                                                  )
                                            )
                                     )
                              )
                        ),
                        tags$div(class="controlPanel", 
                        column(4, align = "center",
                               wellPanel(
                                     selectInput("color", "Select Color Variable", 
                                                 choices = list("No Coloring"   = "none",
                                                                "Primary Genre" = "genre",
                                                                "MPAA Rating"   = "mpaa",
                                                                "Oscar Status" = "oscars")),
                                     textInput("cast", "Specify Actor", placeholder ="e.g. Rob Schneider"),
                                     hr(),
                                     sliderInput("metascore", "MetaCritic Meta Score",
                                                 min = 0, max = 100, value = c(0, 100),
                                                 ticks = FALSE, round = TRUE, step = 1),
                                     sliderInput("userrating", "IMDB User Rating",
                                                 min = 2, max = 9, value = c(2, 9),
                                                 ticks = FALSE, round = TRUE, step = 0.1),
                                     sliderInput("gross", "Total Box Office Gross (Millons)",
                                                 min = 0, max = 750, value = c(0, 750),
                                                 ticks = FALSE, round = TRUE, step = 10),
                                     sliderInput("theaters", "Total Theaters",
                                                 min = 0, max = 4500, value = c(0, 4500),
                                                 ticks = FALSE, round = TRUE, step = 100),
                                     sliderInput("year", "Release Year", 
                                                 min = 2000, max = 2015, value = c(2000, 2015),
                                                 ticks = FALSE, round = TRUE, step = 1),
                                     hr(),
                                     fluidRow(
                                           column(7, align = "left", 
                                                  checkboxGroupInput('genres', h5('Related Genres'), inline = TRUE,
                                                                     choices = c("Comedy", "Drama", "Action", "Thriller", "Adventure", 
                                                                                 "Romance", "Family", "Fantasy", "Crime", "Sci-Fi",
                                                                                 "Horror", "Other"),
                                                                     selected = c("Comedy", "Drama", "Action", "Thriller", "Adventure", 
                                                                                  "Romance", "Family", "Fantasy", "Crime", "Sci-Fi",
                                                                                  "Horror", "Other"))),
                                           column(3, align = "left", checkboxGroupInput('mpaas', h5('MPAA Ratings'), inline = TRUE, width=125,
                                                                                        choices  = c("PG", "PG-13", "R"),
                                                                                        selected = c("PG", "PG-13", "R"))),
                                           column(2, align = "left",checkboxGroupInput('oscars', h5('Oscars'), inline = TRUE, width=75,
                                                                 choices  = c("None", "Nominated", "Won"),
                                                                 selected = c("None", "Nominated", "Won")))
                                          
                                     ),
                                     hr(),
                                     fluidRow(
                                           selectInput('stream', h5('Streaming Service Availability'), 
                                                       choices = c("No Selection", "Netflix", "Amazon", "Hulu"), selected = "No Selection", 
                                                       multiple = FALSE, selectize = TRUE)
                                     ),
                                     hr(),
                                     actionButton("rob", label = "Schneiderize!",
                                                  icon = icon("flash", class = 'glyphicon-flash', lib = 'glyphicon'))
                               )
                        )
                        )
                  )
))