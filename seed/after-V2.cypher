MATCH (ben:Person {name: 'Ben Ortiz'}), (chen:Person {name: 'Chen Li'})
CREATE (acme:Organization {name: 'Acme Analytics'}),
       (ben)-[:WORKS_FOR]->(acme),
       (chen)-[:WORKS_FOR]->(acme);
