import streamlit as st
import sqlite3 as sql
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import altair as alt

##############################################################################
# Theming
##############################################################################
# The theming of seaborn and streamlit is contained here.
# As the rules of the task state, minimal styling is to be used.
st.set_page_config(layout="wide")
sns.set_theme(style="darkgrid")
palette = "blend:#7AB,#EDA"

##############################################################################
# Data ingestion
##############################################################################
# Performing a simple query of the games.db sqlite database.
# The data is cached to speed up and remove reads.

@st.cache_data
def get_data():
    try:
        conn = sql.connect("./data/games.db")
        df = pd.read_sql_query("select * from games", conn, index_col="index")
        return df
    except sql.Error as error:
        print(error)

df = get_data()




tab1, tab2 = st.tabs(["Overview", "Breakdown"])

##############################################################################
# Overview Tab
##############################################################################
# This tab contains graphics that display features about the dataset. 
# This includes:
#    - The dataframe itself, with its numerical features,
#    - A scatter of Plays vs Ratings,
#    - Distribution histograms of Plays and Ratings,
#    - Top n games by Plays and Ratings barcharts,
#    - Pie charts of Genres and Team frequencies.

with tab1:
    st.markdown("## Video Game Shape:")
    
    # Dataframe 
    st.markdown("### Data Table:")
    st.dataframe(df[["title", "rating", "plays", "playing", "backlogs", "wishlist"]], use_container_width=True)
    
    # Altair scatter plot
    st.markdown("### Plays vs Rating:")
    chart = alt.Chart(df).mark_circle().encode(
        x="plays", y="rating", tooltip="title"
    )
    st.altair_chart(chart, use_container_width=True, theme="streamlit")

    # Seaborn interactive histograms
    st.markdown("## Distribution of Ratings and Plays:")
    bins = st.slider("Number of bins:", max_value=40, min_value=5, step=1, key=2)

    col1, col2 = st.columns(2)
    with col1:
        fig1 = plt.figure()
        sns.histplot(data=df, x="rating", bins=bins)
        plt.xlabel("Rating")
        plt.ylabel("")
        st.pyplot(fig1)

    with col2:
        fig2 = plt.figure()
        sns.histplot(df, x="plays", bins=bins)
        plt.xlabel("Plays")
        plt.ylabel("")
        st.pyplot(fig2)

    # Top games by Plays or Rating barcharts
    st.markdown("## Top Games:")
    n = st.slider("Number of games to display:", max_value=50, min_value=5, step=5, key=3)
    
    col1, col2 = st.columns(2)
    # Highest rated bar chart
    with col1:
        df_highest_rated = df[["title", "rating"]].sort_values(by="rating", ascending=False)
        st.markdown("### Highest Rated:")
        fig1 = plt.figure()
        sns.barplot(df_highest_rated.iloc[:n,:], x="title", y="rating", palette=palette)
        plt.xlabel("")
        plt.ylabel("Rating")
        plt.xticks(rotation=90)
        st.pyplot(fig1)

    # Most played bar chart
    with col2:
        df_most_played = df[["title", "plays"]].sort_values(by="plays", ascending=False)
        st.markdown("### Most Played:")
        fig2 = plt.figure()
        sns.barplot(df_most_played.iloc[:n, :], x="title", y="plays", palette=palette)
        plt.xlabel("")
        plt.ylabel("Plays")
        plt.xticks(rotation=90)
        st.pyplot(fig2)

    # Pie charts 
    st.markdown("## Categories Breakdown:")
    col1, col2 = st.columns(2)
        
    # Popular genres pie chart
    with col1:
        st.markdown("### By Genre")

        genre_columns = [column for column in df.columns if "genre" in column]
        dfs = []
        for column in genre_columns:
            temp_df = df.drop([genre for genre in genre_columns if genre != column], axis=1)
            temp_df = temp_df.rename(columns={column: "genre"})
            dfs.append(temp_df)

        genre_df = pd.concat(dfs)
        genre_counts = genre_df["genre"].value_counts()
        genre_counts_top_ten = genre_counts.index[:10]
            
        # Get top 10 genres and put others under "Other"
        pie_genre_data = {"Other": 0}
        for genre, number in genre_counts.items():
            if genre in genre_counts_top_ten:
                pie_genre_data[genre] = number
            else:
                pie_genre_data["Other"] += number
        pie_genre_data = pd.DataFrame(data=[pie_genre_data]).transpose().reset_index()
        pie_genre_data.columns = ["Genre", "Count"]
        chart = alt.Chart(pie_genre_data).mark_arc().encode(
            theta="Count",
            color="Genre"
        )
        st.altair_chart(chart)

    # Popular teams pie chart
    with col2:
        st.markdown("### By Team")

        team_1_df = df.drop("team_2", axis=1)
        team_1_df = team_1_df.rename(columns={"team_1": "team"})
        team_2_df = df.drop("team_1", axis=1)
        team_2_df = team_2_df.rename(columns={"team_2": "team"})

        team_df = pd.concat([team_1_df, team_2_df])
        team_counts = team_df["team"].value_counts()
        team_counts_top_ten = team_counts.index[:10]

        # Get top 10 teams and put others under "Other"
        pie_team_data = {"Other": 0}
        for team, number in team_counts.items():
            if team in team_counts_top_ten:
                pie_team_data[team] = number
            else:
                pie_team_data["Other"] += number
        pie_team_data = pd.DataFrame(data=[pie_team_data]).transpose().reset_index()
        pie_team_data.columns = ["Team", "Count"]

        chart = alt.Chart(pie_team_data).mark_arc().encode(
            theta="Count",
            color="Team"
        )
        st.altair_chart(chart)

##############################################################################
# Breakdown Tab
##############################################################################
# This tab contains information about a specific selected game.
# This includes:
#   - The description of the game,
#   - The teams that made the game,
#   - The genres of the game,
#   - The rating of the game,
#   - The plays of the game,
#   - The number of people playing the game,
#   - The number of people who have the game on their backlog,
#   - The number of people who have the game on their wishlist.

with tab2:
    values = list(df["title"].unique())
    game = st.selectbox(label="Game", options=values)
    
    # Filtered to game and retrieving its elements
    df_game = df[df["title"] == game]
    description = df_game["summary"].values[0]
    
    # Joining teams and genres as csvs
    teams = df_game[[
        "team_1",
        "team_2"
    ]].values[0]
    genres = df_game[[
        "genre_1",
        "genre_2",
        "genre_3",
        "genre_4",
        "genre_5",
        "genre_6",
        "genre_7"
    ]].values[0]
    teams = ", ".join([team for team in teams if team])
    genres = ", ".join([genre for genre in genres if genre])

    rating = df_game["rating"].values[0]
    plays = df_game["plays"].values[0]
    playing = df_game["playing"].values[0]
    backlogs = df_game["backlogs"].values[0]
    wishlist = df_game["wishlist"].values[0]

    # Information about the game
    st.markdown(f"""
                ## Teams:
                {teams}
                """)
    st.markdown(f"""
                ## Genres:
                {genres}
                """)
    st.markdown(f"""
                ## Description:
                {description}
                """)
    
    # Metrics 
    st.markdown("## Metrics:")
    st.metric("Rating:", rating)
    col1, col2 = st.columns(2)
    with col1:
        st.metric("Plays:", f"{plays:,}")
        st.metric("Playing:", f"{playing:,}")
    with col2:
        st.metric("Backlogs:", f"{backlogs:,}")
        st.metric("Wishlist:", f"{wishlist:,}")
    