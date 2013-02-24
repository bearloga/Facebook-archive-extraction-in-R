Facebook archive extraction in R
================================

| By      | Mikhail Y. Popov                                         |
| :---    | :---                                                     |
| email   | [mpopov@cmu.edu](mailto:mpopov@cmu.edu)|
| web     | [http://www.mpopov.com](http://www.mpopov.com)           |

R script[s] to extract data from archives that Facebook allows its users to download.

Open your account settings and click on the download a copy of your Facebook data link there to get to the following page.

A couple of hours later you'll receive an email with the link to download the zipped archive.

Unzip into some directory (and set your working directory to it). Of interest is 'wall.html' in the 'html' subdirectory. You can open it and check it out. We'll use it.

After running the script, you'll have a data frame called **wall** in which every row is a wall post. There are six columns:

- *id* (used for linking comments to posts; see below)
- *author* (since your wall consists of your own posts and posts left on your wall by friends)
- *text* (raw entry content i.e. includes "\n"s)
- *timestamp* (raw)
- *likes* (if any)
- *comments* (number of comments)
- *url* (if a link was attached)
- *datetime* (chron object, used for sorting from oldest to newest)

```
## We can split the whole wall into my posts and everyone else's posts
my.posts <- wall[wall$author==my.FB.name,]
their.posts <- wall[wall$author!=my.FB.name,]

## And then figure out who has left the most posts on my wall!
head(sort(table(their.posts$author),decreasing=T),10)

## And do all sorts of cool analysis and text mining!
```

**Update** The wall data frame now has the number of comments for each post and creates a comments data frame. There are five columns:

- *postid* (used for linking comments to posts; see below)
- *author* (since your wall consists of your own posts and posts left on your wall by friends)
- *content* (raw comment text i.e. includes "\n"s)
- *timestamp* (raw)
- *datetime* (chron object, used for sorting from oldest to newest)

```
## Figure out who has left the most comments across all the posts!
head(sort(table(comments$author),decreasing=T),10)
```

Each comment has an identifier which can be used to link it to any wall post. Although the script calculates the number of comments for each post, how can we use these two data frames to obtain the number of comments for posts only made by me? We can accomplish this using the sqldf package:

```
install.packages("sqldf")
library(sqldf)
sqldf(paste("SELECT wall.id, COUNT(*) AS comments FROM wall
	  JOIN comments ON wall.id = comments.postid
	  WHERE wall.author LIKE '",my.FB.name,"'
	  GROUP BY wall.id",sep=""))
```