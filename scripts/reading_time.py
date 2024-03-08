#!/usr/bin/python3

from bs4 import BeautifulSoup
from bs4 import element as bs4elem
import os
import re

WORDS_PER_MIN = 200


def sort_numerically(lista):
    start_digits = (re.search(r'(?x)^\d+    ', lista) or re.search('inf', 'inf')).group()
    start_non_digits = (re.search(r'(?x)^\D+    ', lista) or re.search(   '',    '')).group()
    end_non_digits = (re.search(r'(?x)\D+$    ', lista) or re.search(   '',    '')).group()
    start_lower = (re.search(r'(?x)^[a-z]+ ', lista) or re.search(   '',    '')).group()
    start_upper = (re.search(r'(?x)^[A-Z]+ ', lista) or re.search(   '',    '')).group()
    all_digits = [float(n) for n in re.findall('\d+', lista) or ['inf']]
    return (float(start_digits), start_non_digits.casefold(), start_upper, start_lower, end_non_digits, all_digits)


def get_text(html_file):
    """Get all readable text from the HTML file."""
    with open(html_file) as f:
        html = f.read()
    soup = BeautifulSoup(html, "html.parser")
    text = soup.findAll(string=True)
    text = filter(is_visible, text)
    return text


def is_visible(element):
    """Check whether the given text element is readable by the user."""
    if element.parent.name in ["style", "script", "[document]", "head", "title"]:
        return False
    elif isinstance(element, bs4elem.Comment):
        return False
    elif element.string == "\n":
        return False
    return True


def calculate_reading_time(text):
    """Calculate total reading time in minutes."""
    # Count the total number of words the user will read.
    total_words = 0
    for current_text in text:
        total_words += len(current_text.string.split(" "))
    # The reading time is a floating number: AB.CDE
    # AB            is the number of minutes needed.
    # .CDE * 60     is the number of seconds. CDE = 500 is equal to 30 seconds (half a minute);
    #               therefore I simply check whether seconds is >= 500 to assign an
    #               extra minute.
    reading_time = str(total_words / WORDS_PER_MIN)
    minutes = int(reading_time.split(".")[0])
    try:
        seconds = int(reading_time.split(".")[1])
        if seconds >= 500:
            minutes += 1
    except IndexError:
        pass
    # Can't be 0.
    if minutes == 0:
        minutes = 1
    return minutes


# Determine path in which to look for archive posts.
PATH_ARCHIVE = os.path.dirname(os.path.abspath(__file__)) + "/../docs/archive/"

FILES = []
for path, subdir, files in os.walk(PATH_ARCHIVE):
    for name in files:
        if name in ["index.html", "chronological.html"]:
            continue
        FILES.append(os.path.join(path, name))

FILES.sort(key=sort_numerically)
for file in FILES[-1:]:
    name = file[file.find("archive/")+8:file.find(".html")]
    print("{}  {:3d} mins".format(name, calculate_reading_time(get_text(file))))
