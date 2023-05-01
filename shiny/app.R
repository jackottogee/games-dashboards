library(shiny)
library(shinythemes)
library(RSQLite)
library(stringr)
library(ggplot2)
library(ggthemes)
library(tidyverse)

# Ingesting data
db <- dbConnect(SQLite(), dbname = "../data/games.db")
data <- dbGetQuery(db, "select * FROM games", stringsAsFactors = FALSE)
dbDisconnect(db)

data <- data[!duplicated(data$title), ] # remove dupes
titles <- array(data$title) # find all titles for dropdown

ui <- fluidPage(theme = shinytheme("lumen"),
    navbarPage(
        "Games Dashboard - Shiny",
        # Home tab
        tabPanel("Home",
            titlePanel("A Shiny App!"),

            mainPanel(
                span(
                    "This is a demo for using shiny to make a 
                    simple dashboard for analytics."
                ),
                span(
                    "The data used in this demo is from is "),
                    a(href = "https://www.kaggle.com/datasets/arnabchaki/
                    popular-video-games-1980-2023", "here!"),
            )
        ), # Home tab end
        # Overview tab
        tabPanel("Overview",
            titlePanel("Video Game Metrics"),
            mainPanel(style = "width:100%",
                h2("Datatable"),
                fluidRow(
                    dataTableOutput("table")
                ),
                h2("Distribution of Ratings and Plays"),
                sliderInput(
                    inputId = "bins",
                    label =   "Number of Bins:",
                    min = 10,
                    max = 40,
                    value = 20
                )
                ,
                fluidRow(
                    column(width = 6,
                        plotOutput(outputId = "ratingDist")
                    ),
                    column(width = 6,
                        plotOutput(outputId = "playDist"))
                ),
                hr(),
                h2("Scatter of Plays Vs Ratings"),
                plotOutput(outputId = "ratingVsPlaysPlot"),
                hr(),
                h2("Top Games by Ratings and Plays"),
                sliderInput(
                        inputId = "maxNum",
                        label = "Number of Games:",
                        min = 5,
                        max = 40,
                        value = 10
                ),
                br(),
                fluidRow(
                    column(width = 6,
                        plotOutput(outputId = "ratingPlot")),
                    column(width = 6,
                        plotOutput(outputId = "playPlot"))
                ),
                hr(),
                h2("Share of Market by Development Teams and Genres"),
                fluidRow(
                    column(width = 6,
                        plotOutput(outputId = "companyPie")),
                    column(width = 6,
                        plotOutput(outputId = "genrePie"))
                )
            )
        ), # Overview tab end
        # Breakdown tab
        tabPanel("Breakdown",
            mainPanel(style = "width:100%",
                selectInput(
                    "game",
                    "Game:",
                    choices = titles
                ),
                fluidRow(
                    column(width = 6,
                        h2("Teams:"),
                        textOutput(outputId = "teams")
                    ),
                    column(width = 6,
                        h2("Genres:"),
                        textOutput(outputId = "genres")
                    )
                ),
                fluidRow(
                    column(width = 12,
                        h2("Description:"),
                        textOutput(outputId = "description"))
                ),
                fluidRow(
                    column(width = 12,
                    h2("Metrics:"))
                ),
                fluidRow(
                    column(width = 12,
                        h3("Rating:"),
                        textOutput(outputId = "rating"))
                ),
                fluidRow(
                    column(width = 6,
                        h3("Plays:"),
                        textOutput(outputId = "plays"),
                        h3("Backlogs:"),
                        textOutput(outputId = "backlogs")
                    ),
                    column(width = 6,
                        h3("Playing:"),
                        textOutput(outputId = "playing"),
                        h3("Wishlist:"),
                        textOutput(outputId = "wishlist")
                    )
                )
            )
        ) # Breakdown tab end
    )
) # fluidPage end

server <- function(input, output) {
    # Datatable with columns title, plays, playing, backlogs and wishlist
    output$table <- renderDataTable(
        data[, c(
            "title",
            "plays",
            "playing",
            "backlogs",
            "wishlist")
        ]
    )

    # Histogram to display distribution of ratings
    output$ratingDist <- renderPlot({
        ggplot(data, aes(x = rating)) %+%
            geom_histogram(color = "red", bins = input$bins, fill = "white") %+%
            scale_x_continuous(name = "Rating") %+%
            scale_y_discrete(name = "") %+%
            theme_minimal() %+%
            theme(axis.text = element_text(size = 12),
                legend.position = "none"
        )
    })

    # Histogram to display distribution of plays
    output$playDist <- renderPlot({
        ggplot(data, aes(x = plays)) %+%
            geom_histogram(color = "blue",
                           bins = input$bins, fill = "white") %+%
            scale_x_continuous(name = "Plays") %+%
            scale_y_discrete(name = "") %+%
            theme_minimal() %+%
            theme(axis.text = element_text(size = 12),
                legend.position = "none"
            )
    })

    # Scatterplot to show plays vs ratings
    output$ratingVsPlaysPlot <- renderPlot({
        ggplot(data, aes(x = plays, y = rating)) %+%
            geom_point() %+%
            scale_x_discrete(name = "Plays") %+%
            scale_y_discrete(name = "Rating") %+%
            theme_minimal() %+%
            theme(axis.text = element_text(size = 12))
    })

    # Bar plot of top games by rating
    output$ratingPlot <- renderPlot({
        # rank by rating desc
        data_ratings <- data[order(-data$rating), ][1:input$maxNum,] 
        ggplot(data = data_ratings,
             aes(x = fct_inorder(title), y = rating,
                 fill = fct_inorder(title))) %+%
                geom_bar(stat = "identity") %+%
                scale_x_discrete(name = "Game") %+%
                scale_y_discrete(name = "Rating") %+%
                theme_minimal() %+%
                theme(axis.text = element_text(size = 12, angle = 90),
                    legend.position = "none"
                )
    })

    # Bar plot of top games by plays
    output$playPlot <- renderPlot({
        # randk by plays desc
        data_plays <- data[order(-data$plays),][1:input$maxNum,] 
        ggplot(data = data_plays, 
            aes(x = fct_inorder(title), y = plays,
                fill = fct_inorder(title))) %+%
            geom_bar(stat = "identity") %+%
            theme(axis.text.x = element_text(angle = 90)) %+%
            scale_x_discrete(name = "Game") %+%
            scale_y_discrete(name = "Plays") %+%
            theme_minimal() %+%
            theme(axis.text = element_text(size = 12, angle = 90),
                legend.position = "none"
            )
    })

    # Pie chart of share by top 10 companies
    output$companyPie <- renderPlot({
        # get all teams
        teams_1 <- data["team_1"]
        teams_2 <- data["team_2"]
        names(teams_1)[1] <- "team"
        names(teams_2)[1] <- "team"
        data_companies <- data.frame(table(rbind(teams_1, teams_2)))

        data_companies <- data_companies[order(-data_companies$Freq),]
        data_companies$team <- as.character(data_companies$team)
        # Any team ranked from 11th onwards renamed to Other
        data_companies[11:nrow(data_companies), ]$team <- "Other"
        # Get share freq
        data_companies <- data_companies %>%
                            group_by(team) %>%
                            summarise(sum(Freq)) %>%
                            as.data.frame()
        names(data_companies)[2] <- "freq"

        ggplot(data_companies, aes(x = "", y = freq, fill = team)) %+%
            geom_bar(stat = "identity", width = 1, color = "white") %+%
            coord_polar("y", start = 0) %+%
            scale_y_discrete(name = "") %+%
            scale_x_discrete(name = "") %+%
            theme_minimal() %+%
            guides(fill = guide_legend(title = "")) %+%
            theme(legend.text = element_text(size = 12))
    })

    # Pie chart of share by genre
    output$genrePie <- renderPlot({
        # get all genres
        for (x in 1:7) {
            genres_x <- data[str_glue("genre_{x}")]
            names(genres_x)[1] <- "genre"
            if (x == 1) {
                genres_array <- genres_x
            } else {
                genres_array <- rbind(genres_array, genres_x)
            }
        }
        genres <- data.frame(table(genres_array))
        ggplot(genres, aes(x = "", y = Freq, fill = genre)) %+%
            geom_bar(stat = "identity", width = 1, color = "white") %+%
            scale_y_discrete(name = "") %+%
            scale_x_discrete(name = "") %+%
            coord_polar("y", start = 0) %+%
            theme_minimal() %+%
            guides(fill = guide_legend(title = "")) %+%
            theme(legend.text = element_text(size = 12))
    })

    # Filter of teams by selected game
    output$teams <- renderText({
        row <- data[data["title"] == input$game][3:4]
        row <- row[!is.na(row)]
        paste(row, collapse = ", ")
        }
    )

    # Filter of genres by selected game
    output$genres <- renderText({
        row <- data[data["title"] == input$game][5:11]
        row <- row[!is.na(row)]
        paste(row, collapse = ", ")
    })

    # Filter of description by selected game
    output$description <- renderText({
        row <- data[data["title"] == input$game][12]
        paste(row)
    })

    # Filter of rating by selected game
    output$rating <- renderText({
        row <- data[data["title"] == input$game][14]
        paste(row)
    })

    # Filter of plays by selected game
    output$plays <- renderText({
        row <- data[data["title"] == input$game][16]
        paste(prettyNum(row, big.mark = ",", format = "f"))
    })

    # Filter of playing by selected game
    output$playing <- renderText({
        row <- data[data["title"] == input$game][17]
        paste(prettyNum(row, big.mark = ",", format = "f"))
    })

    # Filter of backlogs by selected game
    output$backlogs <- renderText({
        row <- data[data["title"] == input$game][18]
        paste(prettyNum(row, big.mark = ",", format = "f"))
    })

    # Filter of wishlist by selected game
    output$wishlist <- renderText({
        row <- data[data["title"] == input$game][19]
        paste(prettyNum(row, big.mark = ",", format = "f"))
    })
}

shinyApp(ui = ui, server = server)
