## Replication Files For "Smoother Ride or Added Distraction? The Role of CarPlay in Fatal Accidents"

This online GitHub repository contains replication files for my [14.33](https://catalog.mit.edu/subjects/14/) paper. 

**Abstract**: Since its introduction in the early 2010s, CarPlay has now become an (almost) ubiquitous feature in newer car models. How does CarPlay affect road safety? On one hand, CarPlay's smooth integration between the driver's smartphone and the car's on-board infotainment system may promote safety; on the other hand, its suite of applications may distract the driver even further. Taking a staggered-adoption event study approach, I find weak evidence that introducing CarPlay may reduce $\sim 5$ deaths per year for a new model year of a vehicle, though results are mixed across different specifications and appear sensitive to functional form assumptions.

**Link to paper:** Will add if I ever decide to make it public.

### 1. Data and Data Cleaning Files

#### 1.1 FARS Data and cleaning

* FARS data can be found here: https://www.nhtsa.gov/file-downloads?p=nhtsa/downloads/FARS/. I use years 2008 to 2021 (the latest available at the time of writing). There are quite a few smaller data sets updated every year. The relevant ones for this project are "vehcile," "accident," and "vpicdecode."
* *clean_fars.do* selects relevant variables for further and merges the files mentioned above over the event period.

#### 1.2 Apple's list of vehicles supporting CarPlay

* *scrape_apple.ipynb* scrapes [this list](https://www.apple.com/ios/carplay/available-models/) from Apple's website. The scraped list is stored under *apple.csv*.
* *query_vin.ipynb* uses [vpic-api](https://github.com/davidpeckham/vpic-api) by David Peckham to query the vehicle's brand ID (makeid) and model ID (modelid). The processed list is matched onto the trimmed FARS data along these two dimensions. The scrapped list with makeid and modelid is stored under *apple_vin.csv.*

### 2. Analysis

* *test_xtevent.do* explores various features of the *xtevent* package in Stata using a simulated data set. It is unreleated to the paper but may be of interest in its own right.
* *figure0.do* creates Figure 0 in the paper.
* *figure1table1.do* creates Figure 1 and Table 1 in the paper.
* *carplayEventStudy.do* implements the key event study designs in the paper.

### 3. Acknowledgement

I thank Professor Isaiah Andrews for his guidance throughout the semester. All mistakes are my own.

