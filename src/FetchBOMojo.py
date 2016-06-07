# import needed modules and set options
#--------------------------------------

import os 
from bs4            import BeautifulSoup 
from urllib.request import urlopen
rootdir = "/Users/elundquist/Documents/Assignments/Data Visualization/project"

# define a function to get the top 100 movies for each year
#----------------------------------------------------------

years = list(range(2000, 2016))
pnums = [1, 2]
mlist = []

for year in years:
    for pnum in pnums:
        
        url = "http://www.boxofficemojo.com/yearly/chart/?page={0}&view=releasedate&view2=domestic&yr={1}&p=.htm".format(pnum, year)
        try:

            page = urlopen(url)
            soup = BeautifulSoup(page)
            rows = soup.find(id="body").find_all("table")[3].find("table").find_all("tr")[2].find("td").find("table").find_all("tr")
                
            # get relevant data from each row
            #--------------------------------

            for i in range(2,102): # skip header row
                title    = rows[i].find_all("td")[1].text
                gross    = rows[i].find_all("td")[3].text
                opening  = rows[i].find_all("td")[5].text
                theaters = rows[i].find_all("td")[4].text

                if i % 10 == 2:
                    print("CURRENT YEAR: {0} CURRENT PAGE: {1} CURRENT MOVIE: {2}".format(year, pnum, title))

                movie = title + "|" + gross + "|" + opening + "|" + theaters + "|" + str(year)
                mlist.append(movie)

        except Exception as e:
            print("\nSomething went wrong.\n")

# get the top 100 movies by total gross from [2000, 2016] and output to text file
#--------------------------------------------------------------------------------

with open(os.path.join(rootdir, 'raw', 'BOMojo.txt'), 'w') as f:
    for m in mlist:
        try:
            f.write(m + '\n')
        except Exception as e:
            pass
print("BO Mojo Movie Data ({0}) Saved Successfully!".format(len(mlist)))

