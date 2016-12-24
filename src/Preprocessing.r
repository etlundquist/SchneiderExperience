library(dplyr)
library(stringr)
setwd('~/Repositories/SchneiderExperience')

# prepare the MovieInfo dataset for analysis
#-------------------------------------------

minfo <- read.delim('raw/MovieInfo.txt', header = TRUE, sep = '|', 
                    stringsAsFactors = FALSE, colClasses = c(imdbid = "character"))
str(minfo); head(minfo)

group_by(minfo, imdbid) %>% filter(n() > 1) %>% select(title, year, imdbid, movieid, gross)
minfo <- ungroup(group_by(minfo, imdbid) %>% filter(row_number() == 1))

minfo$gross    <- as.numeric(str_replace_all(minfo$gross,   '[$,]', ''))
minfo$opening  <- as.numeric(str_replace_all(minfo$opening, '[$,]', ''))
minfo$theaters <- as.numeric(str_replace_all(minfo$theaters,   ",", ''))

genres <- strsplit(minfo$genres, split = ",")
genres <- unlist(genres)

genrefreq <- sort(table(genres), decreasing = TRUE)
genrefreq[1:12]

for (genre in names(genrefreq[13:length(genrefreq)])) {
    minfo$genres <- str_replace(minfo$genres, genre, "Other")
}

table(minfo$mpaarating)
minfo$mpaarating[minfo$mpaarating == "PG-"]   <- "PG"
minfo$mpaarating[minfo$mpaarating == "d"]     <- "PG-13"
minfo$mpaarating[minfo$mpaarating == "13"]    <- "PG-13"
minfo$mpaarating[minfo$mpaarating == "NC-17"] <- "R"
table(minfo$mpaarating)

sapply(minfo, function(x) round(length(x[is.na(x)])/length(x), 2))
round(nrow(minfo[complete.cases(minfo),])/nrow(minfo), 2)
nrow(minfo[complete.cases(minfo),])
minfo <- filter(minfo, !is.na(imdbrating), !is.na(metascore), !is.na(gross))

summary(minfo)
length(unique(minfo$imdbid))
saveRDS(minfo, 'final/SchneiderExperience/data/minfo.rds')

# prepare the VoteBreakdown dataset for analysis
#-----------------------------------------------

vbreak <- read.delim('raw/VoteBreakdown.txt', header = TRUE, sep = '|', 
                     stringsAsFactors = FALSE, colClasses = c(imdbid = "character"))
str(vbreak); head(vbreak)

print.data.frame(group_by(vbreak, imdbid, rating) %>% filter(n() > 1))
vbreak <- ungroup(group_by(vbreak, imdbid, rating) %>% filter(row_number() == 1))

stopifnot(nrow(distinct(vbreak, imdbid, rating)) == nrow(vbreak))
stopifnot(!is.na(vbreak))

summary(vbreak)
length(unique(vbreak$imdbid))
saveRDS(vbreak, 'final/SchneiderExperience/data/vbreak.rds')

# prepare the MovieCast dataset for analysis
#-------------------------------------------

mcast <- read.delim('raw/MovieCast.txt', header = TRUE, sep = '|', 
                    stringsAsFactors = FALSE, colClasses = c(imdbid = "character"))
str(mcast); head(mcast)

smallcast <- group_by(mcast, imdbid) %>% filter(n() < 10) %>% select(imdbid, actor)
filter(minfo, imdbid %in% unique(smallcast$imdbid)) %>% select(imdbid, title, year, gross)

mcast <- ungroup(group_by(mcast, actor) %>% filter(n() > 1))
sort(table(mcast$actor), decreasing = TRUE)[1:20]
sort(table(mcast$actor))[1:20]
length(unique(mcast$actor))

summary(mcast)
length(unique(mcast$imdbid))
saveRDS(mcast, 'final/SchneiderExperience/data/mcast.rds')

# prepare the Awards dataset for analysis
#----------------------------------------

awards <- read.delim('raw/Awards.txt', header = TRUE, sep = '|', 
                     stringsAsFactors = FALSE, colClasses = c(imdbid = "character"))
str(awards); head(awards)

group_by(awards, imdbid) %>% filter(n() > 1)
awards <- ungroup(group_by(awards, imdbid) %>% filter(row_number() == 1))

summary(awards)
length(unique(awards$imdbid))
saveRDS(awards, 'final/SchneiderExperience/data/awards.rds')

# prepare the Streaming dataset for analysis
#-------------------------------------------

streaming <- read.delim('raw/Streaming.txt', header = TRUE, sep = '|', stringsAsFactors = FALSE, colClasses = c(imdbid = "character"))
str(streaming); head(streaming); summary(streaming)

streaming <- distinct(streaming, imdbid, .keep_all = TRUE)
streaming <- left_join(distinct(select(minfo, imdbid)), streaming, by = 'imdbid')

streaming$amazon[is.na(streaming$amazon)]   <- 0
streaming$netflix[is.na(streaming$netflix)] <- 0
streaming$hulu[is.na(streaming$hulu)]       <- 0

streaming$amazon_link[is.na(streaming$amazon_link)]   <- ""
streaming$netflix_link[is.na(streaming$netflix_link)] <- ""
streaming$hulu_link[is.na(streaming$hulu_link)]       <- ""

table(streaming$amazon)
table(streaming$netflix)
table(streaming$hulu)

summary(streaming$imdbid)
length(unique(streaming$imdbid))
saveRDS(streaming, 'final/SchneiderExperience/data/streaming.rds')


