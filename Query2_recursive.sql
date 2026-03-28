-- View 2: recursive
-- idea:
-- start from one root user
-- find users who reshared that user's posts
-- then expand layer by layer through shared posts

CREATE OR REPLACE VIEW project."recursive" AS
WITH RECURSIVE post_net AS (

    -- base case (root user)
    SELECT
        usp.user_id, -- users that reshared starting user's post
        1 AS level -- level counter
    FROM project.posts p
    JOIN project.user_shares_post usp
        ON usp.post_id = p.id
    WHERE p.user_id = 561 -- starting user

    UNION -- no duplicate users

    -- recursive call
    SELECT
        usp2.user_id, -- new users
        pt.level + 1 -- append next layer of users
    FROM post_net pt
    JOIN project.user_shares_post usp1
        ON usp1.user_id = pt.user_id -- users that reshared previous posts
    JOIN project.user_shares_post usp2
        ON usp2.post_id = usp1.post_id -- connecting users through posts
    WHERE usp2.user_id <> pt.user_id -- avoid immediate self-loop
      AND pt.level < 20 -- recursion limit
)

-- select statement
SELECT
    pt.level,
    AVG(p.left_right_score) AS avg_ideology,
    STDDEV(p.left_right_score) AS ideological_variance,
    COUNT(DISTINCT pt.user_id) AS sample_size
FROM post_net pt
JOIN project.posts p
    ON p.user_id = pt.user_id
GROUP BY pt.level
ORDER BY pt.level;