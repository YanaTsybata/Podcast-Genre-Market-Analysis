import csv
import os
import time
from collections import defaultdict

import requests

# Both tables are read from and saved to the folder where this script lives,
# no matter where the terminal is run from
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PODCASTS_CSV = os.path.join(SCRIPT_DIR, "itunes_podcasts.csv")
EPISODES_CSV = os.path.join(SCRIPT_DIR, "itunes_episodes.csv")

TOP_N_PER_GENRE = 10   # how many podcasts to take from each genre
EPISODES_LIMIT = 50    # how many latest episodes to fetch per podcast


def load_podcasts():
    with open(PODCASTS_CSV, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def pick_top_per_genre(rows, n):
    by_genre = defaultdict(list)
    for r in rows:
        by_genre[r["genre"]].append(r)

    selected = []
    for genre, items in by_genre.items():
        items_sorted = sorted(
            items, key=lambda x: int(x["episode_count"] or 0), reverse=True
        )
        selected.extend(items_sorted[:n])
    return selected


def get_episodes(collection_id, limit=EPISODES_LIMIT):
    params = {
        "id": collection_id,
        "media": "podcast",
        "entity": "podcastEpisode",
        "limit": limit,
    }
    resp = requests.get("https://itunes.apple.com/lookup", params=params)
    resp.raise_for_status()
    results = resp.json().get("results", [])
    # the first result is the podcast itself, not an episode, so it is filtered out
    return [r for r in results if r.get("wrapperType") == "podcastEpisode"]


def main():
    podcasts = load_podcasts()
    selected = pick_top_per_genre(podcasts, TOP_N_PER_GENRE)
    print(f"Selected {len(selected)} podcasts, fetching their episodes...")

    rows = []
    for p in selected:
        cid = p["collection_id"]
        episodes = get_episodes(cid)
        for e in episodes:
            rows.append([
                cid,
                e.get("trackId"),
                e.get("trackName"),
                e.get("releaseDate"),
                e.get("trackTimeMillis"),
            ])
        time.sleep(0.3)  # pause between requests so the API is not overloaded

    with open(EPISODES_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            ["collection_id", "episode_id", "episode_title", "release_date", "duration_ms"]
        )
        writer.writerows(rows)

    print(f"Done: {len(rows)} episodes saved to itunes_episodes.csv")


if __name__ == "__main__":
    main()
