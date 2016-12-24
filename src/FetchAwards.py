import os
import re
import time
import requests
import pandas as pd

filepath = '../raw'
minfo    = pd.read_csv(os.path.join(filepath, 'MovieInfo.txt'), sep = '|', dtype = {'imdbid': object})
mids     = list(minfo['imdbid'])
awards   = {'imdbid': [], 'oscars': [], 'awards': []}

i = 0
for mid in mids:

    qparams  = {'i': "tt" + mid, 'r': 'json'}
    response = requests.get('http://www.omdbapi.com', params = qparams)
    
    if response:

        response = response.json()
        
        if re.match(r'^Nominated for [0-9]+ Oscar(s)?', response['Awards'], re.I): 
            awards['oscars'].append('nom')
        elif re.match(r'^Won [0-9]+ Oscar(s)?',response['Awards'], re.I): 
            awards['oscars'].append('won')
        else:                                                                      
            awards['oscars'].append('none')
            
        awards['imdbid'].append(mid)  
        awards['awards'].append(response['Awards'])
        
        if i % 10 == 0:
            print("Current Movie: {0:<40} Awards: [{1}]".format(response['Title'], awards['oscars'][-1]))
            
    else:
        print("Couldn't Find Movie: {0}".format(mid))

    time.sleep(0.5)
    i += 1
    
awards = pd.DataFrame(awards)
print(awards.head(10))

print(awards.oscars.value_counts())
awards.to_csv(os.path.join(filepath, 'Awards.txt'), sep = '|', header = True, index = False, encoding = 'utf8')

        
    

