--
-- PART 2: WINDOWS
-- 
-- strategy: window
-- pattern: A>B
-- k: 2
-- 


    WITH root AS (

  SELECT user_id
       , event_at
       , event_name = 'A' AS is_step_A
       , event_name = 'B' AS is_step_B
    FROM events
   WHERE event_name IN ('A', 'B')

)
       , edge_1 AS (

  SELECT user_id
       , is_step_A AS step_A_match

       , LAG(IFF(step_A_match, event_at, NULL))
           IGNORE NULLS
           OVER (PARTITION BY user_id ORDER BY event_at)
         AS prior_step_A_at

       , is_step_B
           AND event_at < prior_step_A_at + INTERVAL '30 days'
         AS step_B_match
    FROM root

)

  SELECT COUNT(DISTINCT IFF(step_A_match, user_id, NULL)) AS users_A
       , COUNT(DISTINCT IFF(step_B_match, user_id, NULL)) AS users_B
    FROM edge_1
