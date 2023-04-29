library(shiny)
library(shinythemes)
library(RSQLite)
library(stringr)
library(ggplot2)
library(ggthemes)
library(tidyverse)

db <- dbConnect(SQLite(), dbname="../data/games.db")
data <- dbGetQuery(db, "select * FROM games", stringsAsFactors = FALSE)
dbDisconnect(db)

data <- data[!duplicated(data$title), ]
ui <- fluidPage(theme = shinytheme("lumen"),
    navbarPage(
        "Games Dashboard - Shiny",
        tabPanel("Home",
            titlePanel("A Shiny App!"),

            mainPanel(
                span("This is a demo for using shiny to make a simple dashboard for analytics."),
                span("The data used in this demo is from is "), a(href="https://www.kaggle.com/datasets/arnabchaki/popular-video-games-1980-2023", "here!"),
            )
        ),
        tabPanel("Overview",
            titlePanel("Video Game Metrics"),
            mainPanel(style="width:100%",
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
                        plotOutput(outputId= "playDist"))
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
                    column(width=6, 
                        plotOutput(outputId = "ratingPlot")),
                    column(width=6,
                        plotOutput(outputId = "playPlot"))
                ),
                hr(),
                h2("Share of Market by Development Teams and Genres"),
                fluidRow(
                    column(width=6,
                        plotOutput(outputId = "companyPie")),
                    column(width=6,
                        plotOutput(outputId = "genrePie"))
                )
            ) 
        ),
        tabPanel("Breakdown",
            
        )
    )
) # fluidPage

server <- function(input, output) {

    output$ratingDist <- renderPlot({
        ggplot(data, aes(x=rating)) %+% 
            geom_histogram(color = "red", bins = input$bins, fill="white") %+% 
            scale_x_continuous(name="Rating") %+%
            scale_y_discrete(name="") %+%
            theme_minimal() %+%
            theme(axis.text = element_text(size=12),
                legend.position = "none"
            )
    })

    output$playDist <- renderPlot({
        ggplot(data, aes(x=plays)) %+% 
            geom_histogram(color = "blue",bins = input$bins, fill="white") %+%
            scale_x_continuous(name="Plays") %+%
            scale_y_discrete(name="") %+%
            theme_minimal() %+%
            theme(axis.text = element_text(size=12),
                legend.position = "none"
            )
    })

    output$ratingVsPlaysPlot <- renderPlot({
        ggplot(data, aes(x=plays, y=rating)) %+%
            geom_point() %+%
            scale_x_discrete(name="Plays") %+%
            scale_y_discrete(name="Rating") %+%
            theme_minimal() %+%
            theme(axis.text = element_text(size=12))
    })

    output$ratingPlot <- renderPlot({
        data_ratings <- data[order(-data$rating),][1:input$maxNum,]
        ggplot(data=data_ratings, aes(x=fct_inorder(title), y=rating, fill=fct_inorder(title))) %+% 
                geom_bar(stat="identity") %+% 
                scale_x_discrete(name="Game") %+%
                scale_y_discrete(name="Rating") %+%
                theme_minimal() %+%
                theme(axis.text = element_text(size=12, angle=90),
                    legend.position = "none"
                )
    })

    output$playPlot <- renderPlot({
        data_plays <- data[order(-data$plays),][1:input$maxNum,]
        ggplot(data=data_plays, aes(x=fct_inorder(title), y=plays, fill=fct_inorder(title))) %+% 
            geom_bar(stat="identity") %+% 
            theme(axis.text.x = element_text(angle=90)) %+%
            scale_x_discrete(name="Game") %+%
            scale_y_discrete(name="Plays") %+%
            theme_minimal() %+%
            theme(axis.text = element_text(size=12, angle=90),
                legend.position = "none"
            )
    })

    output$companyPie <- renderPlot({
        teams_1 <- data["team_1"]
        teams_2 <- data["team_2"]
        names(teams_1)[1] <- "team"
        names(teams_2)[1] <- "team"
        data_companies <- data.frame(table(rbind(teams_1, teams_2)))
        
        data_companies <- data_companies[order(-data_companies$Freq),]
        data_companies$team <- as.character(data_companies$team)
        data_companies[11:nrow(data_companies),]$team <- "Other"
        data_companies <- data_companies %>% 
                            group_by(team) %>% 
                            summarise(sum(Freq)) %>%
                            as.data.frame()
        names(data_companies)[2] <- "freq"

        ggplot(data_companies, aes(x="", y=freq, fill=team)) %+%
            geom_bar(stat="identity", width=1, color="white") %+%
            coord_polar("y", start=0) %+%
            scale_y_discrete(name="") %+%
            scale_x_discrete(name="") %+%
            theme_minimal() %+%
            guides(fill = guide_legend(title = "")) %+%
            theme(legend.text = element_text(size=12))
    })

    output$genrePie <- renderPlot({
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
        ggplot(genres, aes(x="", y=Freq, fill=genre)) %+%
            geom_bar(stat="identity", width=1, color="white") %+%
            scale_y_discrete(name="") %+%
            scale_x_discrete(name="") %+%
            coord_polar("y", start=0) %+%
            theme_minimal() %+%
            guides(fill = guide_legend(title="")) %+%
            theme(legend.text = element_text(size=12))
    })

}

shinyApp(ui = ui, server = server)
