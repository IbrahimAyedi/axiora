import requests
from bs4 import BeautifulSoup

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
}
url = "https://www.ballouchi.com/annonces/recherche?q=phare+peugeot+208"
try:
    r = requests.get(url, headers=headers, timeout=10)
    print("Status:", r.status_code)
    print("URL:", r.url)
    
    soup = BeautifulSoup(r.text, "html.parser")
    # let's try to find some items
    for item in soup.select('div.item, div.ad, div.annonce, article'):
        title_tag = item.select_one('h2, h3, a.title, a.ad-title, .titre')
        price_tag = item.select_one('.price, .prix')
        link_tag = item.select_one('a')
        
        title = title_tag.text.strip() if title_tag else "No title"
        price = price_tag.text.strip() if price_tag else "No price"
        link = link_tag.get("href") if link_tag else "No link"
        print(title, "-", price, "-", link)
        
    print("Total items found:", len(soup.select('div.item, div.ad, div.annonce, article')))
    
    with open("ballouchi_test.html", "w", encoding="utf-8") as f:
        f.write(r.text)
except Exception as e:
    print("Error:", e)
