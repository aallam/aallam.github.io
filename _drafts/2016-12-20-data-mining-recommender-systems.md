---
title: "Data Mining : Recommender Systems"
layout: post
date: 2016-12-20 18:10
description:
tag:
- Data Mining
blog: true
jemoji:
---

In data mining, a recommender system is an active information filtering system that aims to present the information items that will likely interest the user. For example, Google uses this to show you relevant advertisements, Netflix to recommend you movies that you might like, and Amazon to recommend you relevant products.

The steps to create a recommender system are:
1. Gather information.
2. Organize this information
3. Use this information for the purpose of making a recommendation, as accurate as possible.
The challenge here is to get a dataset and to use it in order to be as accurate as possible in the recommendation process.
As example, let's create a music recommender system.

### Dataset

We will use a database ([link][2]) based on [Million Song Dataset][1].
The database has two tables : train(userID, songID, plays) for train triplets, and song(songID, title, release, artistName, year) for songs metadata.


### Frameworks & Libraries

There are many frameworks and libraries for data mining, for this example, we will use:
* [Scikit-learn][3]: machine learning library for the Python programming language. (free software)
* [Graphlab][4]: is a graph-based, high performance, distributed computation framework. (free for academic use)

### Data Analysis

First, we consider the songs plays as "ratings" for the songs by users, in other words, more a user listens to the same song more he likes it (and higher he evaluates it).
We can do some analysis of the data to get as much information as possible to improve our prediction system afterward. For example, we note that about 58% of the songs were listened to only once.

### Basic Recommender System

The most basic method is simply to recommend the most listened songs ! this method may seem obvious and too easy, but it actually works in many cases and to solve many problems like the cold start.

### Similarity Recommendater

The principle is to base the similarity on the songs listened to by the user. Therefore two songs are considered similar if they were already listened to by the same user (which means the plays/ratings are ignored).
There is many algorithms for item similarity like cosine, pearson... (for Graphlab, jaccard is by default).

### Factorization Recommander

In this category of recommendation algorithm, we have the choice between favoring "ranking performance" (predecting the order of the songs that a user will like) or "rating performance" (predicting the exact number of songs plays by a user).

### Results & Optimization

Based on the analysis of the algorithms, I believe that the RankingFactorizationRecommender class model is best suited for our database.
We note from the analysis we made at the beginning of the database that we can exclude listening to songs listened only once, and we assume that a single play of a song is not enough to take it into consideration. With this logic, we obtain the following model:

### Conclusion

There is many

[1]: http://labrosa.ee.columbia.edu/millionsong/
[2]: https://transfer.sh/o5q2l/msd.sqlite3
[3]: http://scikit-learn.org/
[4]: https://turi.com/
