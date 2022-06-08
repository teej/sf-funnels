# Funnel Analysis in SQL

## How to use this repository

This repository is best paired with the 2022 Snowflake Summit talk [OS303 Funnel Analysis in SQL From Start To Finish](https://www.snowflake.com/summit/agenda?agendaPath=session/824344).

There are many ways to do funnel analysis in SQL. This repository shares code examples of the three most important strategies: JOINs, WINDOWs, and regular expressions. For each, I include a README with a brief breakdown of how that strategy implements step selection, ordering, and time constraints.

Each example uses a table called `events`. This table represents a fictional log of user actions in an app. It contains 3 columns: an integer `user_id`, a timestamp `event_at`, and a varchar `event_name`. For simplicity, all event names are single characters.

You can find a script to create your own events table with sample data in `resources/events.sql`.

```
              ┌──────────┐              
              │  EVENTS  │              
╔═════════════╩──────────╩═════════════╗
║ user_id |    event_at   | event_name ║
╠──────────────────────────────────────╣
║   101     2022-01-01 ...       A     ║
║                                      ║
║   101     2022-01-02 ...       B     ║
║                                      ║
║   101     2022-01-03 ...       C     ║
║                                      ║
║   202     2022-01-01 ...       A     ║
║                                      ║
║   202     2022-01-01 ...       C     ║
╚══════════════════════════════════════╝
```

**SPOILERS**

I have included a bonus fourth strategy: a user-definied table function written in Javascript. This UDTF outperforms pure-SQL strategies for large volumes of data and complex funnel patterns.
