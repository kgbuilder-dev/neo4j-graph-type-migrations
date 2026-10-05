ALTER CURRENT GRAPH TYPE ADD {
  (:Organization => {name :: STRING NOT NULL}),
  (:Person)-[:WORKS_FOR =>]->(:Organization)
};
