MATCH (s:Session)
WHERE NOT EXISTS { (s)-[:IN_ROOM]->(:Room) }
   OR NOT EXISTS { (s)-[:PART_OF]->(:Event) }
RETURN count(s) AS violations;
