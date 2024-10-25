-- Insert into lyceum.user
INSERT INTO player.record (username, password, e_mail)
VALUES ('mmagueta', 'password123', 'mmagueta@example.com'),
       ('lambdu', 'pass123', 'lambdu@example.com');

-- Insert into lyceum.map
INSERT INTO map.instance (name)
VALUES ('CASTLE_HALL'), ('CASTLE_YARD');

-- Insert into lyceum.character and related tables
INSERT INTO character.instance (name, e_mail, username)
VALUES ('Huneric', 'mmagueta@example.com', 'mmagueta'),
       ('Gaiseric', 'mmagueta@example.com', 'mmagueta'),
       ('Legion', 'lambdu@example.com', 'lambdu');

INSERT INTO character.stats (name, e_mail, username, constitution, wisdom, strength, endurance, intelligence, faith)
VALUES ('Huneric', 'mmagueta@example.com', 'mmagueta', 100, 110, 95, 120, 105, 100),
       ('Gaiseric', 'mmagueta@example.com', 'mmagueta', 60, 110, 55, 150, 150, 50),
       ('Legion', 'lambdu@example.com', 'lambdu', 60, 110, 55, 150, 150, 50);

INSERT INTO character.position (name, e_mail, username, x_position, y_position, map_name, face_direction)
VALUES ('Huneric', 'mmagueta@example.com', 'mmagueta', 10, 20, 'CASTLE_HALL', 270),
       ('Gaiseric', 'mmagueta@example.com', 'mmagueta', 15, 15, 'CASTLE_HALL', 270),
       ('Legion', 'lambdu@example.com', 'lambdu', 15, 15, 'CASTLE_HALL', 270);

-- Insert into lyceum.equipment
INSERT INTO equipment.instance (name, description, kind)
VALUES
('Vandal''s Prima', 'A rugged sword of unknown origin, favored by the wild tribes of the West. Its hilt is adorned with a crude carving depicting a dragon''s defeat by a golden warrior. It is said to be a symbol of the tribes'' turbulent beginnings.', 'ARMS'),
('Blood-Reaver''s Gauntlet', 'Fashioned from crude iron in the crucible of barbarian rites, this gauntlet bears primal insignias and the echoes of ancient battles. It is said that those who don this gauntlet unleash the untamed fury of ancestral warriors, their strikes echoing the relentless tide of bloodshed from when the barbarians were feared by the Joniens.', 'ARMS');

-- Insert into lyceum.character_equipment
INSERT INTO equipment.character (name, e_mail, username, is_equiped, equipment_name, use, kind)
VALUES ('Huneric', 'mmagueta@example.com', 'mmagueta', true, 'Vandal''s Prima', 'RIGHT_ARM', 'ARMS'::equipment.kind),
       ('Huneric', 'mmagueta@example.com', 'mmagueta', true, 'Blood-Reaver''s Gauntlet', 'ARMS'::equipment.use, 'ARMS'::equipment.kind),
       ('Gaiseric', 'mmagueta@example.com', 'mmagueta', true, 'Vandal''s Prima', 'RIGHT_ARM', 'ARMS'::equipment.kind),
       ('Legion', 'lambdu@example.com', 'lambdu', true, 'Vandal''s Prima', 'RIGHT_ARM', 'ARMS'::equipment.kind);

-- Insert into lyceum.view_spell_destruction
-- INSERT INTO lyceum.view_spell_destruction (name, description, cost, duration, cast_time, kind, target, base_damage, damage_kind, destruction_kind)
-- VALUES ('Fire Ball', 'Something cool', 10, 50, 1, 'PROJECTILE'::lyceum.spell_type, 'SINGULAR'::lyceum.spell_target, 100, 'FIRE'::lyceum.spell_damage_type, 'MAGIC'::lyceum.spell_destruction_type),
--        ('Ice Ball', 'Another cool thing', 10, 50, 1, 'PROJECTILE'::lyceum.spell_type, 'SINGULAR'::lyceum.spell_target, 100, 'FIRE'::lyceum.spell_damage_type, 'MAGIC'::lyceum.spell_destruction_type);

