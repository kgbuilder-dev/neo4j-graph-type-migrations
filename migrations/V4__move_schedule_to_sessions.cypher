MATCH (t:Talk)-[s:SCHEDULED_AT]->(e:Event)
CALL (t, s, e) {
  MERGE (r:Room {name: s.room})
  MERGE (t)-[:PRESENTED_IN]->(ses:Session {start: s.slot})
  MERGE (ses)-[:IN_ROOM]->(r)
  MERGE (ses)-[:PART_OF]->(e)
} IN TRANSACTIONS OF 1000 ROWS;
