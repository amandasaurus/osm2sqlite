create table tmp_nodes (
    id INTEGER,
    timestamp TEXT,
    user TEXT,
    lat REAL CHECK ( lat <= 90 AND lat >= -90 ),
    lon REAL CHECK ( lon <= 180 AND lon >= -180 )
);

create index tmp_nodes_id ON tmp_nodes ( id );

create table tmp_node_tags (
    node_id INTEGER REFERENCES tmp_nodes ( id ),
    key TEXT,
    value TEXT
);

create table tmp_ways (
    id INTEGER,
    timestamp TEXT,
    user TEXT
);

create index tmp_ways_id ON tmp_ways ( id );

create table tmp_way_tags (
    way_id INTEGER REFERENCES tmp_ways ( id ),
    key TEXT,
    value TEXT
);

create table tmp_way_nodes (
    way_id INTEGER REFERENCES tmp_ways ( id ),
    local_order INTEGER,
    node_id INTEGER REFERENCES tmp_nodes ( id )
);

create table tmp_relations (
    id INTEGER,
    timestamp TEXT,
    user TEXT
);

create index tmp_relations_id ON tmp_relations ( id );

create table tmp_relation_tags (
    relation_id INTEGER REFERENCES tmp_relations ( id ),
    key TEXT,
    value TEXT
);

create table tmp_relation_members (
    relation_id INTEGER REFERENCES tmp_relations ( id ),
    type TEXT CHECK ( type IN ("node", "way", "relation")),
    ref INTEGER,
    role TEXT,
    local_order INTEGER
);


