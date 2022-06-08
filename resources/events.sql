--
-- events.sql
-- 
-- This creates a new table called `events`. This table should be used with the
-- example queries in this repository.
--

  CREATE TABLE events (
         user_id INT
       , event_at TIMESTAMP_NTZ
       , event_name VARCHAR
)

      AS 

  SELECT user_id
       , event_at
       , event_name

    FROM (
          
          VALUES
            (1, '2022-01-01 00:00:00', 'A')
          , (1, '2022-01-01 00:00:01', 'B')
          , (1, '2022-01-01 00:00:02', 'C')

          , (2, '2022-01-01 00:00:00', 'A')

            (3, '2022-01-01 00:00:00', 'A')
          , (3, '2022-01-01 00:00:01', 'B')

          , (4, '2022-01-01 00:00:01', 'B')

          , (5, '2022-01-01 00:00:02', 'C')

          , (6, '2022-01-01 00:00:00', 'A')
          , (6, '2022-04-01 00:00:00', 'B')
          , (6, '2022-07-01 00:00:00', 'C')

          , (7, '2022-01-01 00:00:00', 'A')
          , (7, '2022-01-01 00:00:01', 'B')
          , (7, '2022-01-01 00:00:02', 'A')
          , (7, '2022-01-01 00:00:03', 'C')

         ) AS events (user_id, event_at, event_name)
