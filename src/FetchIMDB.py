# import needed modules and set options
#--------------------------------------

import os
import numpy  as np
import pandas as pd
import imdb
from imdb._exceptions import IMDbError

pd.set_option('display.max_rows',    100)
pd.set_option('display.max_columns',  20)
pd.set_option('display.width',       120)

# bring in the BoxOfficeMojo data 
#--------------------------------

filepath = '../raw'
bomojo = pd.read_csv(os.path.join(filepath, 'BOMojo.txt'), sep = '|', header = None)
bomojo.columns = ['title', 'gross', 'opening', 'theaters', 'year']

# initialize the IMDB connector object and data sets to fill
#-----------------------------------------------------------

# initialize the access object and a not-found list

ia = imdb.IMDb()
notfound = []

# initialize main information, vote breakdown, and cast dictionaries to store API call results

imdbinfo = {'title':      [], 'year':      [], 'movieid': [], 'imdbid': [], 'imdburl':    [],
            'imdbrating': [], 'metascore': [], 'nvotes':  [], 'genres': [], 'mpaarating': []} 
            
vbreakdown = {'imdbid': [], 'rating': [], 'votes': []}
moviecast  = {'imdbid': [], 'actor':  []}
                            
# loop through each movie in the BO Mojo data set and attempt to store IMDB info
#-------------------------------------------------------------------------------
            
for row in bomojo.itertuples():
    
    try:
        
        mid = None
        sresults = ia.search_movie(row.title)
        
        for res in sresults:
            try:
                if (int(res['year']) == int(row.year)) and (res['kind'] == 'movie') and (res['title']):
                    mid = res.movieID
                    break
            except KeyError:
                pass
                
        if mid:  
            
            movie = ia.get_movie(mid, info = ['main', 'critic reviews', 'vote details'])
            print "BOMojo Title: {0: <40} IMDB Title: {1}".format(row.title.encode('utf8'), movie['title'].encode('utf8'))
            
            imdbid     = ia.get_imdbID(movie)
            imdburl    = ia.get_imdbURL(movie)
            imdbrating = movie.get('rating',    'NA')       
            metascore  = movie.get('metascore', 'NA')
            nvotes     = movie.get('votes',     'NA')
            genres     = movie.get('genres',    'NA')
            mpaarating = movie.get('mpaa',      'NA')
            
            if genres     != "NA": genres     = ",".join(genres)
            if mpaarating != "NA": mpaarating = mpaarating[6:mpaarating.index(" ", 6)]
            
            imdbinfo['title'].append(row.title)
            imdbinfo['year'].append(row.year)
            imdbinfo['movieid'].append(mid)
            imdbinfo['imdbid'].append(imdbid)
            imdbinfo['imdburl'].append(imdburl)        
            imdbinfo['imdbrating'].append(imdbrating)
            imdbinfo['metascore'].append(metascore)
            imdbinfo['nvotes'].append(nvotes)
            imdbinfo['genres'].append(genres)
            imdbinfo['mpaarating'].append(mpaarating)   
            
            try:  
                bd = movie['number of votes']
                for i in range(1,11):
                    vbreakdown['votes'].append(bd.get(i, 'NA'))
                    vbreakdown['imdbid'].append(imdbid)
                    vbreakdown['rating'].append(i)
            except KeyError:
                print "MOVIE: {0} DOES NOT HAVE VOTE BREAKDOWN".format(row.title)
                
            try:
                cast = movie['cast']
                for i in range(len(movie['cast'])):
                    moviecast['actor'].append(cast[i]['name'])
                    moviecast['imdbid'].append(imdbid)
                    if i >= 20:
                        break
            except KeyError:
                print "MOVIE: {0} DOES NOT HAVE LISTED CAST".format(row.title)
                
        else:  
            print "MOVIE NOT FOUND: BOMojo Title: {0: <40}".format(row.title)       
            notfound.append(row.title)
            
    except IMDbError as e:
        print "\nIMDB Access Error: {0}".format(e)
        print "Current Title: {0}\n".format(row.title)
    except KeyError as e:
        print "Top-Level Key Access Error"
        print "Current Title: {0}\n".format(row.title)

# merge the IMDB and MOMojo data together and output the result
#--------------------------------------------------------------

imdbinfo   = pd.DataFrame(imdbinfo)
movieinfo  = pd.merge(bomojo, imdbinfo, how = 'inner', on = ['title', 'year'])

vbreakdown = pd.DataFrame(vbreakdown)
moviecast  = pd.DataFrame(moviecast)

print vbreakdown.head()
print vbreakdown.describe()
vbreakdown.to_csv(os.path.join(filepath, 'VoteBreakdown.txt'), sep = '|', header = True, index = False, encoding = 'utf8')

print moviecast.head()
print moviecast.describe()
moviecast.to_csv(os.path.join(filepath, 'MovieCast.txt'), sep = '|', header = True, index = False, encoding = 'utf8')

print movieinfo.head() 
print movieinfo.describe()   
movieinfo.to_csv(os.path.join(filepath, 'MovieInfo.txt'), sep = '|', header = True, index = False, encoding = 'utf8')
