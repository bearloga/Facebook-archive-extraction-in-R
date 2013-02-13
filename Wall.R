my.FB.name <- "Your Full Name On Facebook"
## ^ used later to separate the wall data frame into two data frames
## one containing your posts, one containing everyone else's posts

# install.packages(c("XML","chron",repos="http://lib.stat.cmu.edu/R/CRAN/")
library(chron) # used for manipulating dates and times, good for sorting old-to-new
library(XML) # used for extracting the data from wall.html provided by Facebook

doc <- htmlTreeParse("html/wall.html",useInternalNodes=T)

## Let's fetch all the wall posts from doc
raw.entries <- xpathApply(doc,path="//div[@class='feedentry hentry']")

rm(doc) # doc is no longer needed as we've obtained the wall posts

########## Wall Entries Information Extraction #########
wall <- data.frame(matrix(0,nrow=length(raw.entries),ncol=5))
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
	wall[i,] <- cbind(status.author,status.text,status.timestamp,status.nlikes,status.url)
	
}
## CLEAN UP
rm(status.author,status.text,status.timestamp,status.nlikes,status.url,status.link,comment.like,i)
############

## Tidying-up
names(wall) <- c("author","text","timestamp","likes","url")
wall$author <- factor(wall$author)
wall$url <- as.character(wall$url)
wall$likes <- as.numeric(wall$likes)

## Splitting timestamp into dates and times
timestamp <- strsplit(wall$timestamp,'T')
status_dates <- sapply(timestamp,function(x){x[1]})
status_times <- sapply(timestamp,function(x){substr(x[2],1,8)})

## Create a chron object from the dates and times
status_datetimes <- chron(dates=status_dates,times=status_times,
						 format=c(dates="y-m-d",times="h:m:s"),
						 out.format=c(dates="m/d/y",times="h:m:s"))
wall$datetime <- status_datetimes

## Sort earliest wall post to latest
wall <- wall[order(wall$datetime),]
