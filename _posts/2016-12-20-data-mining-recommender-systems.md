---
title: "Data Mining : Recommender Systems"
layout: post
date: 2016-12-20 18:10
description:
tag:
- Data Mining
blog: true
jemoji:
hidden: true
---

<div class="text-center" markdown="1">
![Datamining words cloud][5]
</div>

In data mining, a recommender system is an active information filtering system that aims to present the information items that will likely interest the user. For example, Google uses this to show you relevant advertisements, Netflix to recommend you movies that you might like, and Amazon to recommend you relevant products.

The steps to create a recommender system are:

1. Gather information.
2. Organize this information
3. Use this information for the purpose of making a recommendation, as accurate as possible.

The challenge here is to get a dataset and to use it in order to be as accurate as possible in the recommendation process.
As example, let's create a music recommender system.

### Dataset

We will use a database based on [Million Song Dataset][1].
The database has two tables : train(userID, songID, plays) for train triplets, and song(songID, title, release, artistName, year) for songs metadata.

* Database : [MSD Sqlite][2] (186,20 Mo)

### Frameworks & Libraries

There are many frameworks and libraries for data mining, for this example :

* [Scikit-learn][3]: machine learning library for the Python programming language. (free software)
* [Graphlab][4]: is a graph-based, high performance, distributed computation framework. (free for academic use)

### Data Analysis

First, we consider the songs plays as "ratings" for the songs by users, in other words, more a user listens to the same song more he likes it (and higher he evaluates it).
We can do some analysis of the data to get as much information as possible to improve our prediction system afterward.

{% highlight Python %}
#!/usr/bin/env python
import numpy as np
import matplotlib.pyplot as plt
import graphlab as gl
import sqlite3

# Loading train triplets
conn = sqlite3.connect("msd.sqlite3")
plays_df = gl.SFrame.from_sql(conn, "SELECT * FROM train")

# Total entries
total_entries = plays_df.num_rows()

# Percentage number of plays of songs
number_listens = []
for i in range(10):
	number_listens.append(float(plays_df[plays_df["plays"] == i+1].num_rows())/total_entries*100)

# Bar plot of the analysis
n = len(number_listens)
x = range(n)
width = 1/1.5
plt.bar(x, number_listens, width, color="blue")
plt.xlabel("Plays"); plt.ylabel("%")
plt.title("the percentage of times the songs were played")
plt.grid(b=True, which="major", color="k", linestyle="-")
plt.grid(b=True, which="minor", color="r", linestyle="-", alpha=0.2)
plt.minorticks_on()
plt.savefig("percentage_song_plays.png")
{% endhighlight %}

<div class="text-center" markdown="1">
![The percentage of times the songs were played][6]
</div>

We note here about 58% of the songs were listened to only once.

### Basic Recommender System

The most basic method is simply to recommend the most listened songs ! this method may seem obvious and too easy, but it actually works in many cases and to solve many problems like the cold start.

{% highlight Python %}
#!/usr/bin/env python
import graphlab as gl
import graphlab.aggregate as agg
import sqlite3

# Loading the DB
conn = sqlite3.connect("msd.sqlite3")

plays_df = gl.SFrame.from_sql(conn, "SELECT * FROM train")
songs_df = gl.SFrame.from_sql(conn, "SELECT * FROM song")

# Get the most listened songs
songs_total_listens = plays_df.groupby(key_columns='songID', operations={"plays": agg.SUM("plays")})

# Join songs with data
songs_total_listens = songs_total_listens.join(songs_df, on="songID", how="inner").sort("plays", ascending=False)
print "# Top Songs with most total lisens:"
print songs_total_listens.print_rows()
{% endhighlight %}

<div class="text-center" markdown="1">
![Basic music recommender system][7]
</div>

### Similarity Recommendater

The principle is to base the similarity on the songs listened to by the user. Therefore two songs are considered similar if they were already listened to by the same user (which means the plays/ratings are ignored).
There is many algorithms for item similarity like _cosine_, _pearson_ and _jaccard_.

In the following code, we will use the Graphlab's [item similarity recommender][8] (which uses _jaccard_ by default) to calculate similarity, train the model, and calculate the [RMSE][9].

{% highlight Python %}
#!/usr/bin/env python
import graphlab as gl
import sqlite3

# Load dataset
conn = sqlite3.connect("msd.sqlite3")
listens = gl.SFrame.from_sql(conn, "SELECT * FROM train")

# Create Training set and test set
train_data, test_data = gl.recommender.util.random_split_by_user(listens, "userID", "songID")

# Train the model
model = gl.item_similarity_recommender.create(train_data, "userID", "songID")

# Evaluate the model
rmse_data = model.evaluate_rmse(test_data, target="plays")

# Print the results
print rmse_data
{% endhighlight %}

We get an overall RMSE of _6.776336098094174_

### Factorization Recommander

In this category of recommendation algorithm, we have the choice between favoring "ranking performance" (predecting the order of the songs that a user will like) or "rating performance" (predicting the exact number of songs plays by a user).

#### Rating Performance :

In case we care mostly about rating performance, then we should use [Factorization Recommender][11] :

{% highlight Python %}
#!/usr/bin/env python
import sqlite3
import graphlab as gl

# Load datasets
conn = sqlite3.connect("msd.sqlite3")
listens = gl.SFrame.from_sql(conn, "SELECT * FROM train")

# Build model
training_data, validation_data = gl.recommender.util.random_split_by_user(listens, "userID", "songID")

# Train the model
model = gl.recommender.factorization_recommender.create(training_data, user_id="userID", item_id="songID", target="plays")

# Evaluate the model
rmse_data = model.evaluate_rmse(validation_data, target="plays")

# Print the results
print rmse_data
{% endhighlight %}

We get a little bit higher overall RMSE of _6.8547462552984095_

#### Ranking Performance :

But If we care about ranking performance, then we should use [Ranking Factorization Recommender][10] instead :

{% highlight Python %}
#!/usr/bin/env python
import sqlite3
import graphlab as gl

# Load datasets
conn = sqlite3.connect("msd.sqlite3")
listens = gl.SFrame.from_sql(conn, "SELECT * FROM train")

# Build model
training_data, validation_data = gl.recommender.util.random_split_by_user(listens, "userID", "songID")

# Train the model
model = gl.recommender.ranking_factorization_recommender.create(training_data, user_id="userID", item_id="songID", target="plays")

# Recommend songs to users
rmse_data = model.evaluate_rmse(validation_data, target="plays")

# Print the results
print rmse_data
{% endhighlight %}

We get clearly a better overall RMSE of _8.342124685755607_


### Results & Optimization

Based on the analysis of the algorithms and the results, clearly, [Ranking Factorization Recommender][10] class model is the best suited for our database.

We note from the analysis we made at the beginning of the database that we can exclude listening to songs listened only once, and we assume that a single play of a song is not enough to take it into consideration:

{% highlight Python %}
#!/usr/bin/env python
import sqlite3
import graphlab as gl

# Load datasets
conn = sqlite3.connect("msd.sqlite3")
listens = gl.SFrame.from_sql(conn, "SELECT * FROM train where plays >=2")

# Build model
training_data, validation_data = gl.recommender.util.random_split_by_user(listens, "userID", "songID")

# Train the model
model = gl.recommender.ranking_factorization_recommender.create(training_data, user_id="userID", item_id="songID", target="plays")

# Evaluate the model
rmse_data = model.evaluate_rmse(validation_data, target="plays")

# Print the results
print rmse_data
{% endhighlight %}

Clearly, we get even better results with this optimization, the overall RMSE is _9.804972175313402_

### Recommend Songs

Let's use an example user to see songs the model recommends for him:

{% highlight Python %}
#!/usr/bin/env python
import sqlite3
import graphlab as gl

# Load datasets
conn = sqlite3.connect("msd.sqlite3")
listens = gl.SFrame.from_sql(conn, "SELECT * FROM train where plays >=2")
songs_df = gl.SFrame.from_sql(conn, "SELECT * FROM song")

# Build model
model = gl.recommender.ranking_factorization_recommender.create(listens, user_id="userID", item_id="songID", target="plays")

# Recommend songs to users
recommendations = model.recommend(users=["fd50c4007b68a3737fe052d5a4f78ce8aa117f3d"])
song_recommendations = recommendations.join(songs_df, on="songID", how="inner").sort("rank")

# Show the results
print song_recommendations
{% endhighlight %}

TA DA ! we get songs recommendations as expected :

<div class="text-center" markdown="1">
![song recommendations results for one user using ranking factorization recommender and excluding song played only once][12]
</div>

If we recommend songs for all the users, we will get the follow plot showing the distribution of calculated scores by rank :

<div class="text-center" markdown="1">
![box whisker plot showing song recommendations results using ranking factorization recommender excluding song played only once][13]
</div>

### Conclusion

Recommendations can be generated by a wide range of algorithms. While user-based or item-based [collaborative filtering][14] methods are simple and intuitive, matrix factorization techniques are usually more effective because they allow us to discover the latent features underlying the interactions between users and items.

Cheers, <br />
Mouaad

### Sources

* [databricks][15]
* [GraphLab : Choosing a Model][17]
* [GraphLab Create API Documentation][16]

[1]: http://labrosa.ee.columbia.edu/millionsong/
[2]: https://www.dropbox.com/s/6t0awghwm5vlam5/msd.sqlite3
[3]: http://scikit-learn.org/
[4]: https://turi.com/
[5]: {{ site.url }}/assets/images/blog/datamining.png
[6]: {{ site.url }}/assets/images/blog/song_recommendation_percentage_song_plays.png
[7]: {{ site.url }}/assets/images/blog/song_recommendation_simple.png
[8]: https://turi.com/products/create/docs/generated/graphlab.recommender.item_similarity_recommender.create.html
[9]: https://en.wikipedia.org/wiki/Root-mean-square_deviation
[10]: https://turi.com/products/create/docs/generated/graphlab.recommender.ranking_factorization_recommender.RankingFactorizationRecommender.html
[11]: https://turi.com/products/create/docs/generated/graphlab.recommender.factorization_recommender.FactorizationRecommender.html
[12]: {{ site.url }}/assets/images/blog/song_recommendation_ranking_factorization_recommender_optim_single_user.png
[13]: {{ site.url }}/assets/images/blog/song_recommendation_ranking_factorization_recommender_box_whisker_optim.png
[14]: https://en.wikipedia.org/wiki/Collaborative_filtering
[15]: https://databricks-prod-cloudfront.cloud.databricks.com/public/4027ec902e239c93eaaa8714f173bcfc/3175648861028866/48824497172554/657465297935335/latest.html
[16]: https://turi.com/products/create/docs/index.html
[17]: https://github.com/turi-code/userguide/blob/master/recommender/choosing-a-model.md
