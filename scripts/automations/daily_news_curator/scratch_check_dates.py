
import feedparser
import datetime

url = "https://blog.bytebytego.com/feed"
parsed = feedparser.parse(url)
for entry in parsed.entries[:5]:
    published = entry.get("published_parsed") or entry.get("updated_parsed")
    pub_dt = datetime.datetime(*published[:6], tzinfo=datetime.timezone.utc)
    print(f"[{pub_dt}] {entry.title}")

url_tc = "https://techcrunch.com/feed/"
parsed_tc = feedparser.parse(url_tc)
for entry in parsed_tc.entries[:5]:
    published = entry.get("published_parsed") or entry.get("updated_parsed")
    pub_dt = datetime.datetime(*published[:6], tzinfo=datetime.timezone.utc)
    print(f"[{pub_dt}] {entry.title}")
