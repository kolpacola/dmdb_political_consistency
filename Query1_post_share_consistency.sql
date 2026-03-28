-- View 1: post_share_consistency
-- Purpose:
-- Compare the average political sentiment of users' own posts
-- with the average sentiment of the posts they share.
-- The result is a consistency score from 0 to 1,
-- where 1 = perfect alignment and 0 = maximum divergence.

CREATE OR REPLACE VIEW project.post_share_consistency AS
WITH post_avg AS (
    -- Average sentiment of each user's own posts
    SELECT
        user_id,
        AVG(left_right_score) AS post_l_r_score,
        AVG(populism_score) AS post_pop_score,
        AVG(affective_polarization) AS post_a_p_score
    FROM project.posts
    GROUP BY user_id
),
share_avg AS (
    -- Average sentiment of the posts each user shared
    SELECT
        usp.user_id,
        AVG(p.left_right_score) AS share_l_r_score,
        AVG(p.populism_score) AS share_pop_score,
        AVG(p.affective_polarization) AS share_a_p_score
    FROM project.user_shares_post usp
    JOIN project.posts p
        ON p.id = usp.post_id
    GROUP BY usp.user_id
)
SELECT
    pa.user_id,

    -- Average scores for original posts and shared posts
    pa.post_l_r_score,
    sa.share_l_r_score,
    pa.post_pop_score,
    sa.share_pop_score,
    pa.post_a_p_score,
    sa.share_a_p_score,

    -- Dimension-specific consistency scores
    -- left_right_score range: 0..2
    1 - ABS(pa.post_l_r_score - sa.share_l_r_score) / 2.0 AS l_r_consistency,

    -- populism_score range: 0..1
    1 - ABS(pa.post_pop_score - sa.share_pop_score) / 1.0 AS pop_consistency,

    -- affective_polarization range: -1..1, so max distance = 2
    1 - ABS(pa.post_a_p_score - sa.share_a_p_score) / 2.0 AS a_p_consistency,

    -- Overall consistency = mean of the three dimension-specific scores
    (
        (1 - ABS(pa.post_l_r_score - sa.share_l_r_score) / 2.0) +
        (1 - ABS(pa.post_pop_score - sa.share_pop_score) / 1.0) +
        (1 - ABS(pa.post_a_p_score - sa.share_a_p_score) / 2.0)
    ) / 3.0 AS overall_consistency

FROM post_avg pa
JOIN share_avg sa
    ON pa.user_id = sa.user_id;