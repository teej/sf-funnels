# PART 2: WINDOWS

## Breakdown

```SQL

    WITH prep AS (

  SELECT user_id
       , event_at
--                            ┌───────────────┐
--                            │  DEFINE STEPS │
--                            └─\ /───────────┘
--                               V 
       , event_name = 'A' AS is_step_A
       , event_name = 'B' AS is_step_B
    FROM events
   WHERE event_name IN ('A', 'B')

)
       , scan AS (

  SELECT user_id
       , is_step_A AS step_A_match
--                            ┌───────────────┐
--                            │   IN ORDER    │
--                            └─\ /───────────┘
--                               V 
       , LAG(IFF(step_A_match, event_at, NULL))
           IGNORE NULLS
           OVER (PARTITION BY user_id ORDER BY event_at)
         AS prior_step_A_at

--                       ┌──────────────┐
--                       │  UNDER TIME  │
--                       │ CONSTRAINTS  │
--                       └─\ /──────────┘
--                          V 
       , is_step_B
           AND event_at < prior_step_A_at + INTERVAL '30 days'
         AS step_B_match
    FROM prep

)
  SELECT COUNT(DISTINCT IFF(step_A_match, user_id, NULL)) AS users_A
       , COUNT(DISTINCT IFF(step_B_match, user_id, NULL)) AS users_B
    FROM scan

```