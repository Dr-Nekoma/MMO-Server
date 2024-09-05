CREATE SCHEMA lyceum;

CREATE TABLE lyceum.user(
       username VARCHAR(32) NOT NULL,
       password TEXT NOT NULL,
       e_mail TEXT NOT NULL CHECK (e_mail ~* '^[A-Za-z0-9.+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
       PRIMARY KEY(username, e_mail)
);

CREATE TABLE lyceum.map(
       name VARCHAR(16) NOT NULL,
       PRIMARY KEY(name)
);

CREATE TYPE lyceum.TILE_TYPE AS ENUM(
       'WATER',
       'GRASS',
       'SAND',
       'ROCK'
);

CREATE TABLE lyceum.tile(
       map_name VARCHAR(16) NOT NULL, 
       kind lyceum.TILE_TYPE NOT NULL,
       x_position SMALLINT NOT NULL,
       y_position SMALLINT NOT NULL,
       PRIMARY KEY(map_name, kind, x_position, y_position),
       FOREIGN KEY (map_name) REFERENCES lyceum.map(name)
);

CREATE TABLE lyceum.object(
       map_name VARCHAR(16) NOT NULL, 
       name VARCHAR(16) NOT NULL,
       x_position SMALLINT NOT NULL,
       y_position SMALLINT NOT NULL,
       PRIMARY KEY(map_name, x_position, y_position),
       FOREIGN KEY (map_name) REFERENCES lyceum.map(name)
);

CREATE OR REPLACE FUNCTION map_object_overlap() RETURNS trigger AS $map_object_overlap$
DECLARE 
    kind TEXT;
BEGIN
    SELECT kind INTO kind FROM tile WHERE x_position = NEW.x_position AND y_position = NEW.y_position;

    IF NEW.name = 'TREE' THEN
        IF kind <> 'GRASS' AND kind <> 'SAND' THEN
            RAISE EXCEPTION '''TREE'' cannot be defined in tiles that are not ''GRASS'' or ''SAND''.';
        END IF;
    END IF;

    RETURN NEW;
END;
$map_object_overlap$ LANGUAGE plpgsql;

CREATE TRIGGER map_object_overlap BEFORE INSERT OR UPDATE ON lyceum.object
FOR EACH ROW EXECUTE FUNCTION map_object_overlap();

CREATE TABLE lyceum.character(
       name VARCHAR(18) NOT NULL,
       e_mail TEXT NOT NULL CHECK (e_mail ~* '^[A-Za-z0-9.+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
       username VARCHAR(32) NOT NULL,
       FOREIGN KEY (e_mail, username) REFERENCES lyceum.user(e_mail, username),
       PRIMARY KEY(name, username, e_mail)
);

CREATE TABLE lyceum.character_stats(
       name VARCHAR(18) NOT NULL,
       e_mail TEXT NOT NULL CHECK (e_mail ~* '^[A-Za-z0-9.+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
       username VARCHAR(32) NOT NULL,
       constitution SMALLINT NOT NULL CHECK (constitution > 0 AND constitution <= 150),
       wisdom SMALLINT NOT NULL CHECK (wisdom > 0 AND wisdom <= 150),
       strength SMALLINT NOT NULL CHECK (strength > 0 AND strength <= 150),
       endurance SMALLINT NOT NULL CHECK (endurance > 0 AND endurance <= 150),
       intelligence SMALLINT NOT NULL CHECK (intelligence > 0 AND intelligence <= 150),
       faith SMALLINT NOT NULL CHECK (faith > 0 AND faith <= 150),
       FOREIGN KEY (name, username, e_mail) REFERENCES lyceum.character(name, username, e_mail),
       PRIMARY KEY(name, username, e_mail)
);

CREATE TABLE lyceum.character_position(
       name VARCHAR(18) NOT NULL,
       e_mail TEXT NOT NULL CHECK (e_mail ~* '^[A-Za-z0-9.+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
       username VARCHAR(32) NOT NULL,
       x_position SMALLINT NOT NULL,
       y_position SMALLINT NOT NULL,
       face_direction SMALLINT NOT NULL CHECK (face_direction >= 0 AND face_direction < 360),	
       map_name VARCHAR(64) NOT NULL,
       FOREIGN KEY (name, username, e_mail) REFERENCES lyceum.character(name, username, e_mail),
       FOREIGN KEY (map_name) REFERENCES lyceum.map(name),
       PRIMARY KEY(name, username, e_mail)
);

CREATE TABLE lyceum.active_characters(
       name VARCHAR(18) NOT NULL,
       e_mail TEXT NOT NULL CHECK (e_mail ~* '^[A-Za-z0-9.+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
       username VARCHAR(32) NOT NULL,
       user_pid VARCHAR(50) NOT NULL UNIQUE,       
       FOREIGN KEY (name, username, e_mail) REFERENCES lyceum.character(name, username, e_mail),
       PRIMARY KEY(name, username, e_mail)      
);

CREATE OR REPLACE VIEW lyceum.view_character AS
SELECT * FROM lyceum.character
NATURAL JOIN lyceum.character_stats
NATURAL JOIN lyceum.character_position;

CREATE OR REPLACE FUNCTION lyceum.view_character_upsert() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO lyceum.character(name, e_mail, username)
    VALUES (NEW.name, NEW.e_mail, NEW.username)
    ON CONFLICT DO NOTHING;

    INSERT INTO lyceum.character_stats(name, e_mail, username, constitution, wisdom, strength, endurance, intelligence, faith)
    VALUES (NEW.name, NEW.e_mail, NEW.username, NEW.constitution, NEW.wisdom, NEW.strength, NEW.endurance, NEW.intelligence, NEW.faith)
    ON CONFLICT (name, e_mail, username) DO UPDATE SET
       name = NEW.name,
       e_mail = NEW.e_mail,
       username = NEW.username,
       constitution = NEW.constitution,
       wisdom = NEW.wisdom,
       strength = NEW.strength,
       endurance = NEW.endurance,
       intelligence = NEW.intelligence,
       faith = NEW.faith,
       face_direction = NEW.face_direction;
    -- Is this really necessary? The on conflict already catches this!
    -- WHERE name = NEW.name AND e_mail = NEW.e_mail AND username = NEW.username;

    INSERT INTO lyceum.character_position(name, e_mail, username, x_position, y_position, map_name)
    VALUES (NEW.name, NEW.e_mail, NEW.username, NEW.x_position, NEW.y_position, NEW.map_name)
    ON CONFLICT (name, username, e_mail) DO UPDATE SET
           name = NEW.name,
           e_mail = NEW.e_mail,
           username = NEW.username,
           x_position = NEW.x_position,
           y_position = NEW.y_position,
           map_name = NEW.map_name;

    -- Same issue here.
    -- WHERE name = NEW.name AND e_mail = NEW.e_mail AND username = NEW.username;

    RETURN NEW;
END
$$;

CREATE TABLE lyceum.item(
       name VARCHAR(32) NOT NULL,
       description TEXT NOT NULL,
       PRIMARY KEY(name)
);

CREATE TABLE lyceum.character_inventory(
       name VARCHAR(18) NOT NULL,
       e_mail TEXT NOT NULL CHECK (e_mail ~* '^[A-Za-z0-9.+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
       username VARCHAR(32) NOT NULL,
       quantity SMALLINT NOT NULL,
       item_name VARCHAR(32) NOT NULL,
       FOREIGN KEY (name, username, e_mail) REFERENCES lyceum.character(name, username, e_mail),
       FOREIGN KEY (item_name) REFERENCES lyceum.item(name),
       PRIMARY KEY(name, username, e_mail, item_name, quantity)
);

CREATE TYPE lyceum.EQUIPMENT_KIND AS ENUM(
       'HEAD',
       'TOP',
       'BOTTOM',
       'FEET',
       'ARMS',
       'FINGER'
);

CREATE TYPE lyceum.EQUIPMENT_USE AS ENUM(
       'HEAD',
       'TOP',
       'BOTTOM',
       'FEET',
       'ARMS',
       'LEFT_ARM',
       'RIGHT_ARM',
       'FINGER'
);

CREATE TABLE lyceum.equipment(
       name VARCHAR(32) NOT NULL,
       description TEXT NOT NULL,
       kind lyceum.EQUIPMENT_KIND NOT NULL,
       PRIMARY KEY(name, kind)
);

CREATE OR REPLACE FUNCTION lyceum.check_equipment_position_compatibility(use lyceum.EQUIPMENT_USE, kind lyceum.EQUIPMENT_KIND) RETURNS BOOL AS $$
BEGIN
    RETURN CASE 
        WHEN use::TEXT = kind::TEXT THEN true
        WHEN use = 'RIGHT_ARM' AND kind = 'ARMS' THEN true
        WHEN use = 'LEFT_ARM' AND kind = 'ARMS' THEN true
        ELSE false
    END;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE lyceum.character_equipment(
       name VARCHAR(18) NOT NULL,
       e_mail TEXT NOT NULL CHECK (e_mail ~* '^[A-Za-z0-9.+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
       username VARCHAR(32) NOT NULL,
       is_equiped BOOL NOT NULL,
       equipment_name VARCHAR(32) NOT NULL,
       use lyceum.EQUIPMENT_USE NOT NULL,
       kind lyceum.EQUIPMENT_KIND NOT NULL,
       CHECK (lyceum.check_equipment_position_compatibility(use, kind)),
       FOREIGN KEY (name, username, e_mail) REFERENCES lyceum.character(name, username, e_mail),
       FOREIGN KEY (equipment_name, kind) REFERENCES lyceum.equipment(name, kind),
       PRIMARY KEY(name, username, e_mail, equipment_name)
);

CREATE OR REPLACE TRIGGER trigger_character_upsert
INSTEAD OF INSERT ON lyceum.view_character
FOR EACH ROW EXECUTE FUNCTION lyceum.view_character_upsert();

-- INSERT INTO lyceum.user(username, e_mail, password)
-- VALUES ('test', 'test@email.com', '123');

-- INSERT INTO lyceum.view_character(name, e_mail, username, constitution, wisdom, strength, endurance, intelligence, faith, x_position, y_position, map_name)
-- VALUES ('knight', 'test@email.com', 'test', 10, 12, 13, 14, 15, 16, 0, 0, 'arda');

-- With map stuff
-- INSERT INTO lyceum.view_character(name, e_mail, username, constitution, wisdom, strength, endurance, intelligence, faith, x_position, y_position, map_name)
-- VALUES ('knight', 'test@email.com', 'test', 10, 12, 13, 14, 15, 16, 0, 0, 'CASTLE_HALL');
