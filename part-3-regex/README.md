# PART 3: REGEX

## Breakdown

```SQL


    WITH prep AS (

  SELECT user_id
       , event_at
       , event_name
    FROM events
--                    ┌───────────────┐
--                    │  DEFINE STEPS │
--                    └─\ /───────────┘
--                       V 
   WHERE event_name IN ('A', 'B', 'C')

)
       , annotated AS (

  SELECT user_id
       , event_at
       , LAG(event_at) OVER (PARTITION BY user_id ORDER BY event_at) AS prior_at
--                                            ┌──────────────┐
--                                            │  UNDER TIME  │
--                                            │ CONSTRAINTS  │
--                                            └─\ /──────────┘
--                                               V 
       , CASE
           WHEN event_at < prior_at + INTERVAL '30 days' 
           THEN '>' ELSE '#'
         END as spacer,
         spacer || event_name as event_token
    FROM prep
)
       , aggregated AS (
  SELECT user_id
--                                         ┌───────────────┐
--                                         │   IN ORDER    │
--                                         └─\ /───────────┘
--                                            V 
       , LISTAGG(event_token) WITHIN GROUP (ORDER BY event_at) AS seq
    FROM annotated
   GROUP BY 1

)

  SELECT COUNT(DISTINCT IFF(seq REGEXP '.*A.*',     user_id, NULL)) AS users_A
       , COUNT(DISTINCT IFF(seq REGEXP '.*A>B.*',   user_id, NULL)) AS users_B
       , COUNT(DISTINCT IFF(seq REGEXP '.*A>B>C.*', user_id, NULL)) AS users_C
    FROM aggregated

```