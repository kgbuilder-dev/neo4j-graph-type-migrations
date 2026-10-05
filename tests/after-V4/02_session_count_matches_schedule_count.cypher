MATCH ()-[s:SCHEDULED_AT]->()
WITH count(s) AS scheduled
MATCH (x:Session)
WITH scheduled, count(x) AS sessions
RETURN abs(scheduled - sessions) AS violations;
