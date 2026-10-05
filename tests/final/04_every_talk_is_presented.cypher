MATCH (t:Talk)
WHERE NOT EXISTS { (t)-[:PRESENTED_IN]->(:Session) }
RETURN count(t) AS violations;
