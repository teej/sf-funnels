# FINALE: UDTF

## Breakdown

```SQL


    WITH prep AS (

  SELECT user_id
       , DATE_PART(epoch_millisecond, event_at)::FLOAT AS event_at_epoch_ms
       , event_name
    FROM events
--                         ┌───────────────┐
--                         │  DEFINE STEPS │
--                         └─\ /───────────┘
--                            V 
   WHERE event_name IN ('A', 'B', 'C', 'D', 'E', 'F', 'G')

)

  SELECT COUNT(DISTINCT IFF(matches[0]::BOOLEAN, user_id, NULL)) AS users_A
       , COUNT(DISTINCT IFF(matches[1]::BOOLEAN, user_id, NULL)) AS users_B
       , COUNT(DISTINCT IFF(matches[2]::BOOLEAN, user_id, NULL)) AS users_C

    FROM prep
       , TABLE(
--                                                ┌──────────────┐
--                                                │  UNDER TIME  │
--                                                │ CONSTRAINTS  │
--                                                └─\ /──────────┘
--                                                   V 
           funnel_matches(event_name, event_epoch, 'A>B>C>D>E>F>G')
--                                   ┌───────────────┐
--                                   │   IN ORDER    │
--                                   └─\ /───────────┘
--                                      V 
           OVER (PARTITION BY user_id ORDER BY event_epoch)
         )

```