MATCH (o:Organization)
DETACH DELETE o;

MATCH (p:Person)
WHERE p.email IS NOT NULL
REMOVE p.email;
