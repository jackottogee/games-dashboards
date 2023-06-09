# Games Dashboards

Encased in this repo is any code contributing to the following pledge:

> I will make four dashboards with four different languages and four different technologies

## Technologies

The following technologies will be used for the project:

- Python, Streamlit
- R, Shiny,
- Julia, ?,
- Javascript, ?

## Constraints

I've set the following contraints on the project to make the project uniform:

- No dash. Plotly dash is crossplatform and I want to showcase the various dashboarding technologies in different languages.
- No excessive styling. I want to showcase what you get out-of-the-box. 
- Same dataset. The same dataset will be used for each of the dashboards, so that they're representing the same underlying data.

## Data

The data used in this project is the [Popular Video Games 1980 - 2023 dataset](https://www.kaggle.com/datasets/arnabchaki/popular-video-games-1980-2023)
from Kaggle.

## Streamlit

First make sure the dependencies are installed via ```pip install -r requirements.txt```. 
Then execute the command from the master directory:
```streamlit run "streamlit/Home.py"```
The app should run.

## Shiny
To execute the Shiny app, start R from the master directory and in the R-console run the command:
```shiny:runApp("shiny/app.R")```
The app should run.
