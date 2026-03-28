-- View 3: consistency_followers_groups
-- idea:
-- count followers for each user
-- split users into follower groups
-- compare average consistency across groups

CREATE OR REPLACE VIEW project."consistency_followers_groups" AS
WITH followers_count AS (

    -- count followers for each user
    SELECT
        u.id AS user_id,
        COUNT(f.follower_id) AS followers_count
    FROM project.users u
    LEFT JOIN project.follows f
        ON u.id = f.followed_id
    GROUP BY u.id
),

grouped_users AS (

    -- join follower counts with consistency scores from Query 1
    SELECT
        psc.user_id,
        psc.l_r_consistency,
        psc.pop_consistency,
        psc.a_p_consistency,
        psc.overall_consistency,
        fc.followers_count,

        -- window function: split users into 3 groups based on actual follower distribution
        NTILE(3) OVER (ORDER BY fc.followers_count, psc.user_id) AS followers_group

    FROM project."post_share_consistency" psc
    JOIN followers_count fc
        ON psc.user_id = fc.user_id
)

-- final grouped output
SELECT
    followers_group,

    -- text labels for groups
    CASE
        WHEN followers_group = 1 THEN 'low followers'
        WHEN followers_group = 2 THEN 'medium followers'
        WHEN followers_group = 3 THEN 'high followers'
    END AS followers_group_label,

    COUNT(*) AS users_count, -- users in each group

    MIN(followers_count) AS min_followers, -- lower bound in group
    MAX(followers_count) AS max_followers, -- upper bound in group

    -- average consistency by dimension
    AVG(l_r_consistency) AS avg_l_r_consistency,
    AVG(pop_consistency) AS avg_pop_consistency,
    AVG(a_p_consistency) AS avg_a_p_consistency,

    AVG(overall_consistency) AS avg_overall_consistency, -- group average
    STDDEV(overall_consistency) AS overall_consistency_stddev, -- spread inside group
    CORR(overall_consistency, followers_count) AS group_correlation -- within-group relationship

FROM grouped_users
GROUP BY followers_group
ORDER BY followers_group;