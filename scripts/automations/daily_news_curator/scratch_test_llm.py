
import sys
import os
from pathlib import Path

_AUTOMATIONS_DIR = "/Users/apple/development/soluni/Solve-for-X/scripts/automations"
sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared.llm_client import LLMClient
from _shared import config

def test_filter():
    config.load_env()
    client = LLMClient()
    
    keywords = ["LLM", "AI", "Rust", "Go", "SRE", "Kubernetes", "k8s", "System Design", "Architecture", "DevOps", "Backend", "infrastructure", "observability", "reliability", "automation", "Flutter", "mobile"]
    keyword_str = ", ".join(keywords)
    
    test_articles = [
        {"title": "How LinkedIn Feed Uses LLMs to Serve 1.3 Billion Users", "summary": "Technical details on how LinkedIn scale their LLM infrastructure."},
        {"title": "The Best Coffee Shops in London", "summary": "A guide to coffee in the UK capital."}
    ]
    
    for article in test_articles:
        prompt = (
            f"Keywords of interest: {keyword_str}\n\n"
            f"Article title: {article['title']}\n"
            f"Article summary: {article['summary'][:300]}\n\n"
            f"Is this article relevant to any of the keywords above? "
            f"Reply with ONLY 'yes' or 'no'."
        )
        print(f"\nTesting: {article['title']}")
        response = client.ask(
            user_prompt=prompt,
            use_external=False, 
            max_tokens=5,
            temperature=0.0,
        )
        print(f"Response: '{response}'")

if __name__ == "__main__":
    test_filter()
