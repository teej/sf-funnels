--
-- PART 1: THE JOIN
-- 
-- strategy: join-bin
-- pattern: A>B>C
-- k: 3
-- 

SET sequence_duration_sec = 2 * 60 * 60;
SET bin_size_sec = $sequence_duration_sec * 5;

     WITH prep AS (

   SELECT user_id
        , event_at
        , event_name
        , FLOOR(DATE_PART(epoch_second, event_at) / ($bin_size_sec)) AS bin
     FROM events
    WHERE event_name IN ('A', 'B', 'C')

    UNION ALL

   SELECT user_id
        , event_at
        , event_name
        , FLOOR(DATE_PART(epoch_second, event_at) / ($bin_size_sec)) AS bin
     FROM events
    WHERE event_name IN ('A', 'B', 'C')

      AND DATE_PART(epoch_second, event_at) % $bin_size_sec >= $bin_size_sec - $sequence_duration_sec

)

   SELECT COUNT(DISTINCT step_A.user_id) AS users_A
        , COUNT(DISTINCT step_B.user_id) AS users_B
        , COUNT(DISTINCT step_C.user_id) AS users_C

     FROM prep AS step_A

     LEFT JOIN prep AS step_B
       ON step_B.event_name = 'B'
      AND step_B.user_id = step_A.user_id
      AND step_B.bin = step_A.bin
      AND step_B.event_at > step_A.event_at
      AND step_B.event_at < step_A.event_at + INTERVAL '1 hour'

     LEFT JOIN prep AS step_C
       ON step_C.event_name = 'C'
      AND step_C.user_id = step_B.user_id
      AND step_C.bin = step_B.bin
      AND step_C.event_at > step_B.event_at
      AND step_C.event_at < step_B.event_at + INTERVAL '1 hour'

    WHERE step_A.event_name = 'A'
