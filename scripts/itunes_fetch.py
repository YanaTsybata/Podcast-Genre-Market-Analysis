import requests
import csv
import time

BASE_URL = "https://itunes.apple.com/search"

# Search terms: they roughly cover the main podcast genres
SEARCH_TERMS = [
    "true crime", "business", "comedy", "news", "technology",
    "health", "education", "sports", "society and culture",
    "science", "history", "arts", "fiction", "kids and family",
    "religion and spirituality", "tv and film", "music", "politics",
]


def search_podcasts(term, limit=200, country="US"):
    params = {
        "term": term,
        "media": "podcast",
        "entity": "podcast",
        "limit": limit,
        "country": country,
    }
    resp = requests.get(BASE_URL, params=params)
    resp.raise_for_status()
    return resp.json().get("results", [])


def main():
    seen_ids = set()
    rows = []

    for term in SEARCH_TERMS:
        results = search_podcasts(term)
        for r in results:
            cid = r.get("collectionId")
            if cid is None or cid in seen_ids:
                continue
            seen_ids.add(cid)
            rows.append([
                cid,
                r.get("collectionName"),
                r.get("artistName"),
                r.get("primaryGenreName"),
                r.get("trackCount"),
                r.get("releaseDate"),
                r.get("country"),
            ])
        time.sleep(0.3)  # pause between requests so the API is not overloaded

    with open("itunes_podcasts.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            ["collection_id", "title", "author", "genre", "episode_count", "last_release_date", "country"]
        )
        writer.writerows(rows)

    print(f"Done: {len(rows)} podcasts saved to itunes_podcasts.csv")


if __name__ == "__main__":
    main()
