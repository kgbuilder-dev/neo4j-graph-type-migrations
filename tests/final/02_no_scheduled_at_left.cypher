MATCH ()-[s:SCHEDULED_AT]->()
RETURN count(s) AS violations;
