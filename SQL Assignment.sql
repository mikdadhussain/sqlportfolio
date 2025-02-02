--Part 1 - 1   (Loading and exploring Data)
SELECT TOP 10 * FROM badges;
SELECT TOP 10 * FROM comments;
SELECT TOP 10 * FROM post_history;
SELECT TOP 10 * FROM post_links;
SELECT TOP 10 * FROM posts_answers;
SELECT TOP 10 * FROM tags;
SELECT TOP 10 * FROM users;
SELECT TOP 10 * FROM votes;
SELECT TOP 10 * FROM posts;

desc badges;
desc comments;
desc post_history;
desc post_links;
desc posts_answers;
desc tags;
desc users;
desc votes;
desc posts;

SELECT COUNT(*)  FROM badges;
SELECT COUNT(*)  FROM comments;
SELECT COUNT(*)  FROM post_history;
SELECT COUNT(*)  FROM post_links;
SELECT COUNT(*)  FROM posts_answers;
SELECT COUNT(*)  FROM tags;
SELECT COUNT(*)  FROM users;
SELECT COUNT(*)  FROM votes;
SELECT COUNT(*)  FROM posts;

--Part 1 - 2   Filtering and Sorting

SELECT id, post_id, user_id, creation_date, text
FROM comments
WHERE creation_date >= '2012-01-01' AND creation_date < '2013-01-01'
ORDER BY creation_date ASC;

--Part 1 - 3    Simple Aggregation
SELECT COUNT(DISTINCT id) AS total_unique_badges FROM badges;
select AVG(post_type_id) from posts_answers;

--Part 2 - 1 . a    Basic Joins
SELECT 
    p.title AS post_title,
    ph.text AS history_text,
    ph.creation_date AS history_creation_date
FROM 
    posts p
JOIN 
    post_history ph
ON 
    p.id = ph.post_id
ORDER BY 
    p.title, ph.creation_date;


--Part 2 - 1 . b    Basic Joins

SELECT 
    u.id AS user_id,
    u.display_name AS user_name,
    COUNT(b.id) AS total_badges_earned
FROM 
    users u
LEFT JOIN 
    badges b
ON 
    u.id = b.user_id
GROUP BY 
    u.id, u.display_name
ORDER BY 
    total_badges_earned DESC;


--Part 2 - 2 . a   Multitable Joins

SELECT 
    p.title AS post_title,
    c.text AS comment_text,
    u.display_name AS commenter_name
FROM 
    posts p
JOIN 
    comments c
ON 
    p.id = c.post_id
JOIN 
    users u
ON 
    c.user_id = u.id
ORDER BY 
    p.title, c.creation_date;


--Part 2 - 2 . b   Multitable Joins

SELECT u.id AS user_id,
    u.display_name AS user_name,
    u.reputation,
    b.name AS badge_name,
    b.date AS badge_date,
    c.text AS comment_text,
    c.creation_date AS comment_date
FROM 
    users u
JOIN 
    badges b
ON 
    u.id = b.user_id
JOIN 
    comments c
ON 
    u.id = c.user_id
ORDER BY 
    u.display_name, b.date, c.creation_date;


--Part 3 - 1 . a  Single Row Subquery

SELECT id, display_name, reputation, creation_date
FROM  users ORDER BY reputation DESC;


--Part 3 - 1 . b  Single Row Subquery

WITH RankedPosts AS (
    SELECT id, title, post_type_id, creation_date, score, view_count,  owner_user_id,
        ROW_NUMBER() OVER (PARTITION BY post_type_id ORDER BY score DESC) AS rank
    FROM
        posts
)
SELECT id, title, post_type_id, creation_date, score, view_count, owner_user_id
FROM
    RankedPosts
WHERE
    rank = 1;


--Part 3 - 2   Corelated Subquries

SELECT
    post_id, COUNT(related_post_id) AS related_post_count
FROM
    post_links
GROUP BY
    post_id
ORDER BY
    related_post_count DESC;

--Part 4 - 1 


--Part 4 - 2     Recursive CTE

WITH RECURSIVE PostHierarchy AS (
    -- Anchor member: Start with the root post(s)
    SELECT
        post_id AS root_post_id,
        related_post_id AS linked_post_id,
        1 AS level -- Level of hierarchy (starting from 1)
    FROM
        post_links
    WHERE
        post_id = 1 -- Specify the root post ID to start the hierarchy
    UNION ALL
    -- Recursive member: Traverse the hierarchy
    SELECT
        ph.root_post_id,
        pl.related_post_id AS linked_post_id,
        ph.level + 1 AS level -- Increment the level
    FROM
        PostHierarchy ph
    JOIN
        post_links pl
    ON
        ph.linked_post_id = pl.post_id
)
SELECT
    root_post_id,
    linked_post_id,
    level
FROM
    PostHierarchy
ORDER BY
    root_post_id, level;


--Part 5 - 1 . a   Windows Function

WITH PostYear AS (
    SELECT
        id,
        title,
        post_type_id,
        creation_date,
        score,
        view_count,
        owner_user_id,
        EXTRACT(YEAR FROM creation_date) AS post_year -- Extract the year from creation_date
    FROM
        posts
)
SELECT
    id,
    title,
    post_type_id,
    creation_date,
    score,
    view_count,
    owner_user_id,
    post_year,
    RANK() OVER (PARTITION BY post_year ORDER BY score DESC) AS rank_within_year
FROM
    PostYear
ORDER BY
    post_year DESC, rank_within_year;


--Part 5 - 1 . b   Windows Function

SELECT
    user_id,
    name AS badge_name,
    date AS badge_date,
    SUM(1) OVER (PARTITION BY user_id ORDER BY date) AS running_total_badges
FROM
    badges
ORDER BY
    user_id, date;



--Insight - 1   New Insight and Questions

WITH user_comments AS (
    SELECT 
        user_id, 
        COUNT(*) AS comment_count
    FROM 
        comments
    GROUP BY 
        user_id
),
user_edits AS (
    SELECT 
        user_id, 
        COUNT(*) AS edit_count
    FROM 
        post_history
    WHERE 
        post_history_type_id = 2  -- Assuming type 2 represents edits
    GROUP BY 
        user_id
),
user_votes AS (
    SELECT 
        user_id, 
        COUNT(*) AS vote_count
    FROM 
        votes
    GROUP BY 
        user_id
),
combined_contributions AS (
    SELECT
        u.id AS user_id,
        u.display_name,
        COALESCE(uc.comment_count, 0) AS comment_count,
        COALESCE(ue.edit_count, 0) AS edit_count,
        COALESCE(uv.vote_count, 0) AS vote_count,
        (COALESCE(uc.comment_count, 0) + COALESCE(ue.edit_count, 0) + COALESCE(uv.vote_count, 0)) AS total_contributions
    FROM
        users u
    LEFT JOIN
        user_comments uc ON u.id = uc.user_id
    LEFT JOIN
        user_edits ue ON u.id = ue.user_id
    LEFT JOIN
        user_votes uv ON u.id = uv.user_id
)
SELECT
    user_id,
    display_name,
    comment_count,
    edit_count,
    vote_count,
    total_contributions
FROM
    combined_contributions
ORDER BY
    total_contributions DESC;


--Insight - 2 New Insight and Questions

SELECT 
    name AS badge_name, 
    COUNT(*) AS badge_count
FROM 
    badges
GROUP BY 
    name
ORDER BY 
    badge_count DESC;


--Insight - 3       New Insight and Questions


WITH post_scores AS (
    SELECT
        p.id AS post_id,
        p.score,
        pt.tag_id
    FROM
        posts p
    JOIN
        post_tags pt ON p.id = pt.post_id
),
tag_scores AS (
    SELECT
        t.id AS tag_id,
        t.tag_name,
        SUM(ps.score) AS total_score
    FROM
        tags t
    JOIN
        post_scores ps ON t.id = ps.tag_id
    GROUP BY
        t.id, t.tag_name
)
SELECT
    tag_id,
    tag_name,
    total_score
FROM
    tag_scores
ORDER BY
    total_score DESC;

 
--Insight - 4     New Insight and Questions

SELECT 
    COUNT(*) AS total_related_links
FROM 
    post_links;