# import needed modules and set options
#--------------------------------------

import os

from bs4            import BeautifulSoup 
from urllib.request import urlopen

# define a function to pull all available NetFlix titles
#-------------------------------------------------------

results = {'title': [], 'year': []}

for i in range(1,1000):

    print("Currently Fetching Data from Page: {0}".format(i))
    url = "http://usa.istreamguide.com/movies?direction=asc&movies=1&page={0}&shows=0&sort=s_title".format(i)

    page = urlopen(url)
    soup = BeautifulSoup(page)

    titles = [title.find('a').text for title in soup.find_all('span', {'class': 'title'})]
    years  = [year.text for year in soup.find_all('span', {'class': 'year'})]

    # assert len(titles) == len(years), "Number of Titles & Years does not Match"

    for i in range(len(titles)):
        results['title'].append(titles[i])
        # results['year'].append(years[i])

print(results)



