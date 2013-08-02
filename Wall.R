my.FB.name <- "Your Full Name On Facebook"
## ^ used later to separate the wall data frame into two data frames
## one containing your posts, one containing everyone else's posts

# install.packages(c("XML","chron",repos="http://lib.stat.cmu.edu/R/CRAN/")
library(chron) # used for manipulating dates and times, good for sorting old-to-new
library(XML) # used for extracting the data from wall.html provided by Facebook
library(plyr) # used for making the comments data frame

doc <- htmlTreeParse("html/wall.html",useInternalNodes=T)

## Let's fetch all the wall posts from doc
raw.entries <- xpathApply(doc,path="//div[@class='feedentry hentry']")

rm(doc) # doc is no longer needed as we've obtained the wall posts

########## Wall Entries Information Extraction #########
wall <- data.frame(matrix(0,nrow=length(raw.entries),ncol=7))
comments <- list(rep(NULL,length(raw.entries)))
for ( i in 1:length(raw.entries) ) {
  ## Wall post and timestamp
	status.text <- xmlValue(getNodeSet(raw.entries[[i]],
						path="span[@class='entry-title entry-content']")[[1]])
	status.timestamp <- as.character(xmlAttrs(getNodeSet(raw.entries[[i]],
						path="div[@class='timerow']/abbr[@class='time published']")[[1]])["title"])
	## Number of likes (if any)
	if ( length(comment.like <- getNodeSet(raw.entries[[i]],
			path="div[@class='comments hfeed']/div[@class='comment like']")) > 0 ) {
		status.nlikes <- as.numeric(strsplit(xmlValue(comment.like[[1]]),,split=" ")[[1]][1])
	} else {
		status.nlikes <- 0
	}
	## Number of comments
	status.ncomments <- length(getNodeSet(raw.entries[[i]],path="div[@class='comments hfeed']/div[@class='comment hentry']"))
	if ( status.ncomments > 0 ) { # let's get those comments!
		status.comments <- getNodeSet(raw.entries[[i]],path="div[@class='comments hfeed']/div[@class='comment hentry']")
		comments[[i]] <- ldply(lapply(status.comments,function(status.comment){
			comment.author <- xmlValue(getNodeSet(status.comment,path="span[@class='author']/span[@class='profile fn']")[[1]])
			comment.content <- xmlValue(getNodeSet(status.comment,path="span[@class='entry-title entry-content']")[[1]])
			comment.timestamp <- as.character(xmlAttrs(getNodeSet(status.comment,
																  path="div/abbr[@class='time published']")[[1]])["title"])
			return(data.frame(postid=i,author=comment.author,content=comment.content,timestamp=comment.timestamp))
		}))
	}
	## The URL of the attached link (if any)
	if (!is.null((status.link <- getNodeSet(raw.entries[[i]],
			path="span[@class='entry-title entry-content']/table[@class='walllink']/tr/td/a")))) {
		status.url <- as.character(xmlAttrs(status.link[[length(status.link)]])["href"])
	} else {
		status.url <- NA
	}
	## The author of the post (friends can leave posts on your wall)
	status.author <- xmlValue(getNodeSet(raw.entries[[i]],
						path="span[@class='author vcard']/span[@class='profile fn']")[[1]])
	## Let's add this extracted information to the data frame
	wall[i,] <- cbind(id=i,status.author,status.text,status.timestamp,status.nlikes,status.ncomments,status.url)	
}
## CLEAN UP
rm(raw.entries)
rm(status.author,status.text,status.timestamp,
   status.nlikes,status.url,status.link,comment.like,i,status.ncomments,
   status.comments)
############

## Tidying-up
comments <- ldply(comments)
comments$timestamp <- as.character(comments$timestamp)
comments$content <- as.character(comments$content)
comments$author <- factor(comments$author)
comments$postid <- as.numeric(comments$postid)

names(wall) <- c("id","author","text","timestamp","likes","comments","url")
wall$author <- factor(wall$author)
wall$text <- as.character(wall$text)
wall$timestamp <- as.character(wall$timestamp)
wall$url <- as.character(wall$url)
wall$likes <- as.numeric(wall$likes)
wall$comments <- as.numeric(wall$comments)

## Splitting timestamp into dates and times
timestamp <- strsplit(wall$timestamp,'T')
status_dates <- sapply(timestamp,function(x){x[1]})
status_times <- sapply(timestamp,function(x){substr(x[2],1,8)})
## Create a chron object from the dates and times
status_datetimes <- chron(dates=status_dates,times=status_times,
						  format=c(dates="y-m-d",times="h:m:s"),
						  out.format=c(dates="m/d/y",times="h:m:s"))
wall$datetime <- status_datetimes
rm(status_dates,status_times,status_datetimes,timestamp)
## Let's do the same tiemstamp processing for comments
## Splitting timestamp into dates and times
timestamp <- strsplit(comments$timestamp,'T')
comments_dates <- sapply(timestamp,function(x){x[1]})
comments_times <- sapply(timestamp,function(x){substr(x[2],1,8)})
## Create a chron object from the dates and times
comments_datetimes <- chron(dates=comments_dates,times=comments_times,
							format=c(dates="y-m-d",times="h:m:s"),
							out.format=c(dates="m/d/y",times="h:m:s"))
comments$datetime <- comments_datetimes
rm(comments_dates,comments_times,comments_datetimes,timestamp)

## Sort earliest wall post & comment to latest
wall <- wall[order(wall$datetime),]
comments <- comments[order(comments$datetime),]
