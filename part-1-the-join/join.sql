--
-- PART 1: THE JOIN
-- 
-- strategy: join
-- pattern: A>B
-- k: 2
-- 

  SELECT COUNT(DISTINCT step_A.user_id) AS users_A
       , COUNT(DISTINCT step_B.user_id) AS users_B

    FROM events AS step_A

    LEFT JOIN events AS step_B
      ON step_B.event_name = 'B'
     AND step_B.user_id = step_A.user_id
     AND step_B.event_at > step_A.event_at
     AND step_B.event_at < step_A.event_at + INTERVAL '30 days' 

   WHERE step_A.event_name = 'A'
