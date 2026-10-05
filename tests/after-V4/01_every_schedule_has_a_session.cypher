MATCH (t:Talk)-[s:SCHEDULED_AT]->(e:Event)
WHERE NOT EXISTS {
  (t)-[:PRESENTED_IN]->(:Session {start: s.slot})-[:PART_OF]->(e)
}
RETURN count(*) AS violations;
