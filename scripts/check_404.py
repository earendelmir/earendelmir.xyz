#!/usr/bin/python3

from bs4 import BeautifulSoup
import requests
import os


def get_links(file):
    with open(file) as f:
        html = f.read()
    soup = BeautifulSoup(html, "html.parser")
    soup_links = soup.find_all("a")
    links = []
    for link in soup_links:
        href = str(link.get("href"))
        if href.startswith("/"):
            links.append("https://earendelmir.xyz" + href)
        elif href.startswith("#") and len(href) > 1:
            links.append("https://earendelmir.xyz/" + file[file.find("docs/")+5:] + href)
        elif href.startswith("mailto"):
            continue
        elif href == "data:,":
            continue
        elif href == "":
            continue
        elif href is None:
            continue
        else:
            links.append(href)
    return links

def get_url_status(url):
    try:
        r = requests.get(url)
        if str(r.status_code) == "404":
            print(f"ERROR {url}: 404")
            return False
    except Exception as e:
        print(f"ERROR {url}: {e}\n")
        return False
    return True


PATH_ROOT = os.path.dirname(os.path.abspath(__file__)) + "/../docs/"
FILES = []
LINKS_TESTED = {}

for path, subdir, files in os.walk(PATH_ROOT):
    for name in files:
        if name.endswith(".html"):
            if name in ["template.html", "skeleton.html", "skeleton_notes.html"]:
                continue
            FILES.append(os.path.join(path, name))

for file in FILES:
    fname = file[file.find("docs/")+5:file.find(".html")]
    if fname.endswith("/index"):
        fname = fname[:-5]
    print("=== URL CHECKING IN", fname)
    links = get_links(file)
    for l in links:
        if l == "None": continue
        if LINKS_TESTED.get(l) is None:
            get_url_status(l)
            LINKS_TESTED[l] = 1
