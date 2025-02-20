CREATE TABLE IF NOT EXISTS map.object_is_resource(
       kind map.OBJECT_TYPE NOT NULL,
       capacity INTEGER NOT NULL CHECK (0 < capacity),
       base_extraction_amount INTEGER NOT NULL CHECK (0 < base_extraction_amount),
       base_extraction_time INTEGER NOT NULL CHECK (0 < base_extraction_time),
       name TEXT NOT NULL,
       description TEXT NOT NULL,
       item_pk TEXT NOT NULL,
       PRIMARY KEY (kind),
       FOREIGN KEY (item_pk) REFERENCES character.item(name)
);

CREATE TABLE IF NOT EXISTS map.resource(
       map_name TEXT NOT NULL,
       -- TODO: Add constraint depending on the same kind and position of the tile.
       -- Some objects should only be able to put on top of if they are on a specific kind of tile
       kind map.OBJECT_TYPE NOT NULL,
       quantity INTEGER NOT NULL DEFAULT 50 CHECK (0 <= quantity),
       x_position REAL NOT NULL,
       y_position REAL NOT NULL,
       -- TODO: Some items have face direction for us to care, e.g., like chest
       -- face_direction SMALLINT NOT NULL CHECK (face_direction >= 0 AND face_direction < 360) DEFAULT 270,
       PRIMARY KEY (map_name, kind, x_position, y_position),
       FOREIGN KEY (kind) REFERENCES map.object_is_resource(kind),
       FOREIGN KEY (map_name, kind, x_position, y_position) REFERENCES map.object(map_name, kind, x_position, y_position)
);

CREATE OR REPLACE VIEW map.resource_view AS
SELECT * FROM map.resource
NATURAL JOIN map.object_is_resource
NATURAL JOIN map.object;

CREATE OR REPLACE FUNCTION map.resource_management_view() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN -- FIXME
    IF NEW.quantity = 0
     THEN
       DELETE FROM map.resource
       WHERE map_name = NEW.map_name and kind = NEW.kind and x_position = NEW.x_position and y_position = NEW.y_position;
     ELSE
       UPDATE map.resource
       SET quantity = NEW.quantity
       WHERE map_name = NEW.map_name and kind = NEW.kind and x_position = NEW.x_position and y_position = NEW.y_position;
     END IF;
END
$$;

CREATE TRIGGER resource_management_trigger
  INSTEAD OF INSERT OR UPDATE ON map.resource_view
  FOR EACH ROW
  EXECUTE PROCEDURE map.resource_management_view();

CREATE OR REPLACE FUNCTION object_is_resource() RETURNS TRIGGER
   LANGUAGE plpgsql AS
$$
  BEGIN
  IF EXISTS (SELECT kind, capacity FROM map.object_is_resource
              WHERE kind = new.kind AND new.quantity <= capacity)
   THEN
     RETURN new;
   END IF;
   RAISE exception 'Object is not a resource.';
END;
$$;

CREATE CONSTRAINT TRIGGER object_is_resource_trigger
  AFTER INSERT OR UPDATE ON map.resource
  DEFERRABLE INITIALLY IMMEDIATE
  FOR EACH ROW
  EXECUTE PROCEDURE object_is_resource();


CREATE OR REPLACE PROCEDURE map.harvest_resource
   (target_map_name TEXT, target_kind map.OBJECT_TYPE, target_x_position REAL, target_y_position REAL, player_name TEXT, player_e_mail TEXT, player_username TEXT)
   LANGUAGE plpgsql AS
$$
  DECLARE resource map.resource_view%rowtype;
          delta INTEGER;
  BEGIN
  SELECT * INTO resource
    FROM map.resource_view
    WHERE map.resource_view.map_name = target_map_name
    AND map.resource_view.kind = target_kind
    AND map.resource_view.x_position = target_x_position
    AND map.resource_view.y_position = target_y_position;
  SELECT min(x) INTO delta FROM (values(resource.quantity),(resource.base_extraction_amount)) AS t(x);
  UPDATE map.resource_view
    SET quantity = resource.quantity - delta
    WHERE map_name = target_map_name
      AND kind = target_kind
      AND x_position = target_x_position
      AND y_position = target_y_position;
  CALL character.update_inventory(player_name, player_e_mail, player_username, resource.item_pk, delta);
END;
$$;
