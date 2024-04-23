import requests
from bs4 import BeautifulSoup

# URL of the website you want to scrape
url = "https://www.apple.com/ios/carplay/available-models/"

# Send a GET request to the URL
response = requests.get(url)

# Check if the request was successful
if response.status_code == 200:
    # Parse the HTML content of the page
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Now you can use BeautifulSoup to extract information from the page
    # For example, let's extract all the <a> tags (links) on the page
    links = soup.find_all('section-content')
    
    # Print out the URLs of all the links found on the page
    for link in links:
        print(link.get('href'))
else:
    print('Failed to retrieve the webpage')
