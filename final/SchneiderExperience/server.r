library(ggvis)
library(dplyr)
library(stringr)
library(Hmisc)

# bring in the data files needed for the viz
#-------------------------------------------

minfo     <- select(readRDS('data/minfo.rds'), title:genres, imdbid, imdbrating, metascore, mpaarating)
vbreak    <- readRDS('data/vbreak.rds')
mcast     <- readRDS('data/mcast.rds')
mawards   <- readRDS('data/awards.rds')
streaming <- readRDS('data/streaming.rds')
minfo     <- inner_join(minfo, streaming, by = 'imdbid')

# minor data cleaning and manipulation
#-------------------------------------------

minfo$genres <- apply(as.matrix(minfo$genres), 1, function(x) sub("Mystery", "Thriller", x)[[1]])

mawards$oscars <- apply(as.matrix(mawards$oscars), 1, function(x) sub("none", "None", x)[[1]])
mawards$oscars <- apply(as.matrix(mawards$oscars), 1, function(x) sub("won", "Won", x)[[1]])
mawards$oscars <- apply(as.matrix(mawards$oscars), 1, function(x) sub("nom", "Nominated", x)[[1]])
minfo <- merge(x = minfo, y = mawards[ , c("imdbid", "oscars")], by = "imdbid", all.x=TRUE)

# define the main shinyServer() function
#---------------------------------------

shinyServer(function(input, output) {
      

    # subset the MovieInfo data based on current filter conditions
    #-------------------------------------------------------------
    
    minfoFilter <- reactive({
          
        hoverMovie$imdbid = NULL
        
        minmetascore <- input$metascore[1]
        maxmetascore <- input$metascore[2]
        
        minuserrating <- input$userrating[1]
        maxuserrating <- input$userrating[2]
          
        mingross <- input$gross[1] * 1e6
        maxgross <- input$gross[2] * 1e6
        
        minyear <- input$year[1]
        maxyear <- input$year[2]
        
        mintheaters <- input$theaters[1]
        maxtheatres <- input$theaters[2]
        
        genres <- input$genres
        mpaas  <- input$mpaas
        oscars <- input$oscars
        stream <- input$stream
        
        filtered <- filter(minfo, 
                           imdbrating >= minuserrating & imdbrating <= maxuserrating,
                           metascore >= minmetascore & metascore <= maxmetascore,
                           gross    >= mingross    & gross    <= maxgross,
                           year     >= minyear     & year     <= maxyear,
                           theaters >= mintheaters & theaters <= maxtheatres,
                           apply(as.matrix(minfo$genres), 1, function(x) 
                               length(intersect(unlist(strsplit(x, split = ",")), input$genres))) > 0,
                           apply(as.matrix(minfo$mpaarating), 1, function(x) 
                               length(intersect(x, input$mpaas))) > 0,
                           apply(as.matrix(minfo$oscars), 1, function(x) 
                                 length(intersect(x, input$oscars))) > 0
        )
        
        if (str_trim(input$cast) != "") {
            curactor <- str_replace_all(str_trim(str_to_upper(input$cast)), "[^A-Z]", "")
            amovies  <- unique(filter(mcast, str_replace_all(str_trim(str_to_upper(actor)), "[^A-Z]", "") == curactor)$imdbid)
            filtered <- filter(filtered, imdbid %in% amovies)
        }
        
        if      (stream == "Amazon")  filtered <- filter(filtered, amazon  == 1)
        else if (stream == "Netflix") filtered <- filter(filtered, netflix == 1)
        else if (stream == "Hulu")    filtered <- filter(filtered, hulu    == 1)

        if (input$rob %% 2) {
            amovies  <- unique(filter(mcast, str_trim(str_to_upper(actor)) == "ROB SCHNEIDER")$imdbid)
            filtered <- filter(minfo, imdbid %in% amovies)
        }
        
        filtered
    })
                          
    # generate the tooltip for each point on the main scatter
    #--------------------------------------------------------
    
    minfoTooltip <- function(x) {
        
        if (is.null(x) | is.null(x$imdbid)) {
            return(NULL)
        }
        
        curmovies <- isolate(minfoFilter())
        curmovie  <- curmovies[curmovies$imdbid == x$imdbid,]
        
        paste("<b>", curmovie$title, "</b>", " (", curmovie$year, ")", "<br>", 
              "IMDB Rating: ", curmovie$imdbrating, "<br>",
              "MetaScore: ",   curmovie$metascore,  "<br>",
              "Total Gross: ", format(curmovie$gross, big.mark = ",", scientific = FALSE), 
        sep = "")
    }
    
    # store the IMDBID of the current scatterplot hover selection in a reactive list
    #-------------------------------------------------------------------------------
    
    hoverMovie <- reactiveValues(imdbid = NULL)
    hoverScatter <- function(data, ...) {
        hoverMovie$imdbid <- data$imdbid
    }
    
    # build the dataset needed for the hover-specific vote-breakdown bar chart
    #-------------------------------------------------------------------------
    
    vbreakFilter <- reactive({
        if (is.null(hoverMovie$imdbid)) {
            vbreak
        }
        else {
            filter(vbreak, imdbid == hoverMovie$imdbid)
        }
    })
    
    # store all needed movie info for the current scatterplot hover selection
    #------------------------------------------------------------------------
    
    vbreakInfo <- reactive({
        vinfo    <- list()
        curbreak <- vbreakFilter()
        if (is.null(hoverMovie$imdbid)) {
            vinfo$title <- "Movie Ratings Breakdown"
            vinfo$year  <- "All Years"
            vinfo$sd    <- sqrt(wtd.var(curbreak$rating, curbreak$votes))
            vinfo$link  <- ""
        }
        else {
            curmovie    <- filter(minfoFilter(), imdbid == hoverMovie$imdbid)
            vinfo$title <- curmovie$title[1]
            vinfo$year  <- curmovie$year[1]
            vinfo$sd    <- sqrt(wtd.var(curbreak$rating, curbreak$votes))
            if      (input$stream == "Amazon")  vinfo$link <- curmovie$amazon_link
            else if (input$stream == "Netflix") vinfo$link <- curmovie$netflix_link
            else if (input$stream == "Hulu")    vinfo$link <- curmovie$hulu_link
        }
        vinfo
    })
    
    # build the main scatterplot visualization
    #-----------------------------------------
    
    movieScatter <- reactive({
        
        # fetch the MovieInfo data subject to current filter conditions
        
        curmovies <- minfoFilter()
        xvar_name <- "IMDB User Rating"
        yvar_name <- "MetaCritic Meta Score"
        
        # define a vector to map to the fill property based on user input
        
        if (input$color == "none") {
            curmovies$fillvec <- rep("All Movies", times = nrow(curmovies))
        }
        else if (input$color == "genre") {
            curmovies$fillvec <- apply(as.matrix(curmovies$genres), 1, function(x) strsplit(x, split = ",")[[1]][1])
        }
        else if (input$color == "mpaa") {
            curmovies$fillvec <- curmovies$mpaarating
        }
        else if (input$color == "oscars") {
              curmovies$fillvec <- curmovies$oscars
        }
        
        # define the main visualization object

        vis <- ggvis(curmovies, x = ~imdbrating, y = ~metascore) %>%
            layer_points(size               = ~gross,
                         fill               = ~factor(fillvec), 
                         fillOpacity       := 0.70, 
                         fillOpacity.hover := 1.00,
                         key               := ~imdbid) %>%
            add_tooltip(minfoTooltip, "hover")         %>%
            add_axis("x", title = xvar_name)           %>%
            add_axis("y", title = yvar_name)           %>%
            add_legend("fill", title = "")             %>% 
            hide_legend("size")                        %>%
            scale_numeric("size", range = c(25, 250))  %>%
            scale_numeric("x", domain = c(input$userrating[1],input$userrating[2]))  %>%
            scale_numeric("y", domain = c(input$metascore[1], input$metascore[2]))  %>%
            handle_hover(hoverScatter)                 %>%
            set_options(width = "auto", height = "auto")
        
        if (input$rob %% 2) {
            vis <- vis %>% layer_images(width := 40, height := 40,
                url      := "http://everythinghapa.com/wp-content/uploads/2015/01/EH_Profiles_RobSchneider.png",
                baseline := "middle",
                align    := "center"
            )
        }
        
        vis
    })
    movieScatter %>% bind_shiny("scatter")
    
    # build the reactive vote breakdown visualization
    #------------------------------------------------
    
    ratingBars <- reactive({
        ggvis(vbreakFilter(), x = ~rating, y = ~votes) %>% 
            layer_bars(stroke       := 'black',
                       fill         := '#1565c0',
                       fill.hover   := '#999999',
                       fillOpacity  := 0.9)                               %>%
            add_axis("x", title = "IMDB User Rating", values = 1:10)          %>%
            add_axis("y", title = "Number of Ratings", title_offset = 80, ticks=5) %>%
            set_options(width = "auto", height = "auto")
    })
    ratingBars %>% bind_shiny("bars")
    
    # produce the aggregate descriptive text
    #---------------------------------------
    
    output$nmovies <- renderText({ nrow(minfoFilter()) })
    output$r_ab    <- renderText({ round(cor(minfoFilter()$imdbrating, minfoFilter()$gross),     2) })
    output$r_cb    <- renderText({ round(cor(minfoFilter()$metascore,  minfoFilter()$gross),     2) })
    output$r_ac    <- renderText({ round(cor(minfoFilter()$imdbrating, minfoFilter()$metascore), 2) })
    
    # produce the movie-specific descriptive text
    #--------------------------------------------
    
    output$mtitle <- renderText({ vbreakInfo()$title        })
    output$myear  <- renderText({ vbreakInfo()$year         })
    output$msd    <- renderText({ round(vbreakInfo()$sd, 2) })
    output$link   <- renderUI({   a(vbreakInfo()$link, class = "web", href = vbreakInfo()$link, target="_blank") })  
    
})

