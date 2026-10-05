OPTIONAL MATCH (o:Organization)
WITH count(o) AS organizations
OPTIONAL MATCH (p:Person) WHERE p.email IS NOT NULL
WITH organizations, count(p) AS emails
RETURN organizations + emails AS violations;
