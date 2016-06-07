# import needed modules and set options
#--------------------------------------

import os
import numpy  as np
import pandas as pd
from canistreamit import search, streaming

# bring in the main MovieInfo data
#---------------------------------

filepath  = '../raw'
minfo     = pd.read_csv(os.path.join(filepath, 'MovieInfo.txt'), sep = '|', dtype = {'imdbid': object})
sresults  = {'imdbid':[], 'netflix':[], 'netflix_link':[], 'amazon':[], 'amazon_link':[], 'hulu':[], 'hulu_link':[]}
notfound  = []

# lookup available streaming options for each movie
#--------------------------------------------------

for row in minfo.itertuples():
    
    try: 

        title  = row[1]
        imdbid = row[7]
        
        print("Current Search Title: {0} ({1})".format(title, imdbid))
        slist = search(title)
        movie = None
        
        if slist:
            for res in slist:
                try:
                    matchid = res['links']['imdb'].split("/")[-2].replace("tt","").strip()
                    if imdbid == matchid:
                        movie = res
                        break
                except KeyError:
                    pass
                   
        if movie:    
            
            stream = streaming(movie['_id'])
            netflix, amazon, hulu = 0, 0, 0
            netflix_link, amazon_link, hulu_link = "", "", ""
            
            if stream:
                
                if 'netflix_instant' in stream.keys():
                    try:
                        netflix = 1
                        netflix_link = "https://www.netflix.com/title/" + stream['netflix_instant']['external_id']
                    except KeyError:
                        pass
                        
                if 'hulu_movies' in stream.keys():
                    try:
                        hulu = 1
                        hulu_link = stream['hulu_movies']['direct_url']
                    except KeyError:
                        pass
                    
                if 'amazon_prime_instant_video' in stream.keys():
                    try:
                        amazon = 1
                        amazon_link = stream['amazon_prime_instant_video']['direct_url']     
                    except KeyError:
                        pass
                          
            sresults['imdbid'].append(imdbid)
            sresults['netflix'].append(netflix)
            sresults['amazon'].append(amazon)
            sresults['hulu'].append(hulu)
            sresults['netflix_link'].append(netflix_link)
            sresults['amazon_link'].append(amazon_link)
            sresults['hulu_link'].append(hulu_link)
            
        else:
            print("Could Not Find Matching Title")
            notfound.append(title)
            
    except Exception:
        "Movie: {0} Caused a Problem".format(title)
        
# export streaming results to an external file
#---------------------------------------------
        
sresults = pd.DataFrame(sresults)
print(sresults.describe())
print(sresults.head(10))
print(sresults.netflix.value_counts())
print(sresults.amazon.value_counts())
print(sresults.hulu.value_counts())
sresults.to_csv(os.path.join(filepath, 'Streaming.txt'), sep = '|', header = True, index = False)

        
