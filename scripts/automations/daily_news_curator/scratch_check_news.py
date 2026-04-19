
import yaml
import feedparser
from pathlib import Path

FEEDS_YAML = "/Users/apple/development/soluni/Solve-for-X/scripts/automations/daily_news_curator/feeds.yaml"

def fetch():
    with open(FEEDS_YAML, "r") as f:
        config = yaml.safe_load(f)
    
    all_articles = []
    for feed in config["feeds"]:
        print(f"Fetching: {feed['name']}")
        try:
            parsed = feedparser.parse(feed["url"])
            for entry in parsed.entries[:5]: # Top 5 from each
                all_articles.append({
                    "title": entry.title,
                    "summary": getattr(entry, "summary", entry.get("description", ""))
                })
        except Exception as e:
            print(f"Error fetching {feed['name']}: {e}")
    
    print(f"\nTotal fetched: {len(all_articles)}")
    for i, a in enumerate(all_articles):
        print(f"{i+1}. {a['title']}")

if __name__ == "__main__":
    fetch()
