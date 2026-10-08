-- How many podcasts already exist in each genre?

SELECT genre, COUNT(*) AS count_genre
FROM `podcast.itunes_podcasts`
GROUP BY genre;


-- How many episodes has a podcast published on average in each genre?

SELECT genre, CAST(ROUND(AVG(episode_count)) AS INT64) AS avg_episodes, COUNT(*) AS total_podcasts
FROM `podcast.itunes_podcasts`
GROUP BY genre
ORDER BY avg_episodes DESC;


-- How many podcasts in each genre are still active?
-- Active = latest episode within 180 days before the reference date, 25 September 2026

WITH base AS (
  SELECT
    genre,
    DATE_DIFF(DATE('2026-09-25'), DATE(last_release_date), DAY) AS days_since_release
  FROM `podcast.itunes_podcasts`
),
labeled AS (
  SELECT
    genre,
    CASE
      WHEN days_since_release <= 180 THEN 'Active'
      ELSE 'Inactive'
    END AS status
  FROM base
)
SELECT
  genre,
  COUNT(*) AS total_podcasts,
  COUNTIF(status = 'Active') AS active_count,
  ROUND(COUNTIF(status = 'Active') / COUNT(*) * 100, 1) AS active_percent
FROM labeled
GROUP BY genre
ORDER BY active_percent DESC;


-- What is the typical episode duration of the leading podcasts in each genre?
-- Genres with at least 10 podcasts in the full table. The median is approximate (APPROX_QUANTILES).

WITH big_genres AS (
  SELECT genre
  FROM `podcast.itunes_podcasts`
  GROUP BY genre
  HAVING COUNT(*) >= 10
)
SELECT
  p.genre,
  COUNT(DISTINCT p.collection_id) AS podcasts_in_sample,
  ROUND(APPROX_QUANTILES(e.duration_ms, 2)[OFFSET(1)] / 60000, 1) AS median_duration_min,
  COUNT(e.duration_ms) AS episodes_used,
  COUNT(*) AS episodes_total
FROM `podcast.itunes_episodes` AS e
INNER JOIN `podcast.itunes_podcasts` AS p
  ON e.collection_id = p.collection_id
INNER JOIN big_genres AS b
  ON p.genre = b.genre
GROUP BY p.genre
ORDER BY median_duration_min DESC;


-- How many podcasts and genres are there in total?

SELECT COUNT(*) AS total_podcasts, COUNT(DISTINCT genre) AS total_genres
FROM `podcast.itunes_podcasts`;


-- How many genres have only one podcast?

SELECT COUNT(*) AS genres_with_one_podcast
FROM (
  SELECT genre
  FROM `podcast.itunes_podcasts`
  GROUP BY genre
  HAVING COUNT(*) = 1
);


-- How many genres have at least 10 podcasts?

SELECT COUNT(*) AS genres_with_10_plus_podcasts
FROM (
  SELECT genre
  FROM `podcast.itunes_podcasts`
  GROUP BY genre
  HAVING COUNT(*) >= 10
);


-- How many episodes have all podcasts published in total?

SELECT SUM(episode_count) AS total_episodes
FROM `podcast.itunes_podcasts`;


-- How many podcasts are active overall, and how many genres have only active podcasts?

WITH labeled AS (
  SELECT
    genre,
    DATE_DIFF(DATE('2026-09-25'), DATE(last_release_date), DAY) <= 180 AS is_active
  FROM `podcast.itunes_podcasts`
),
by_genre AS (
  SELECT genre, COUNT(*) AS total, COUNTIF(is_active) AS active
  FROM labeled
  GROUP BY genre
)
SELECT
  SUM(active) AS active_podcasts,
  SUM(total) AS total_podcasts,
  ROUND(SUM(active) / SUM(total) * 100) AS active_percent,
  COUNTIF(active = total) AS genres_fully_active,
  COUNTIF(active < total) AS genres_with_inactive
FROM by_genre;


-- How many podcasts have a last release date after the reference date?

SELECT COUNT(*) AS podcasts_after_reference_date
FROM `podcast.itunes_podcasts`
WHERE DATE(last_release_date) > DATE('2026-09-25');


-- What does the episodes table contain: size, coverage, dates, missing and extreme durations?

SELECT
  COUNT(*) AS episodes,
  COUNT(DISTINCT collection_id) AS podcasts_with_episodes,
  MIN(release_date) AS first_release,
  MAX(release_date) AS last_release,
  COUNTIF(duration_ms IS NULL) AS missing_duration,
  ROUND(MIN(duration_ms) / 60000, 1) AS min_duration_min,
  ROUND(MAX(duration_ms) / 60000, 1) AS max_duration_min
FROM `podcast.itunes_episodes`;


-- Which episode_count values are the most frequent?

SELECT episode_count, COUNT(*) AS podcasts
FROM `podcast.itunes_podcasts`
GROUP BY episode_count
ORDER BY podcasts DESC
LIMIT 3;


-- How many podcasts did the collection script select for episode data (up to 10 per genre)?

SELECT SUM(LEAST(10, podcasts)) AS selected_podcasts
FROM (
  SELECT genre, COUNT(*) AS podcasts
  FROM `podcast.itunes_podcasts`
  GROUP BY genre
);
