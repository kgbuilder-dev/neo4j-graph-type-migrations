ALTER CURRENT GRAPH TYPE ADD {
  (:Session => {start :: LOCAL DATETIME NOT NULL, recording :: STRING}),
  (:Room => {name :: STRING NOT NULL, capacity :: INTEGER}),
  (:Talk)-[:PRESENTED_IN =>]->(:Session),
  (:Session)-[:IN_ROOM =>]->(:Room),
  (:Session)-[:PART_OF =>]->(:Event)
};
