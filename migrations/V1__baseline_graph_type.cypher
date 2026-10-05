ALTER CURRENT GRAPH TYPE SET {
  (:Person => {name :: STRING NOT NULL, email :: STRING}),
  (:Talk => {title :: STRING NOT NULL, level :: STRING}),
  (:Topic => {name :: STRING NOT NULL}),
  (:Event => {name :: STRING NOT NULL, date :: DATE NOT NULL}),
  (:Person)-[:PRESENTS =>]->(:Talk),
  (:Talk)-[:ABOUT =>]->(:Topic),
  (:Talk)-[:SCHEDULED_AT => {room :: STRING NOT NULL, slot :: LOCAL DATETIME NOT NULL}]->(:Event)
};
