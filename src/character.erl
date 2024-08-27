-module(character).

-export([create/2, player_characters/3, update/2, updateTemp/2, retrieve_near_players/3, activate/3, deactivate/2, retrieve/2]).

create(#{name := Name, 
	 username := Username, 
	 email := Email,
	 constitution := Constitution,
	 wisdom := Wisdom,
	 strength := Strength,
	 endurance := Endurance,
	 intelligence := Intelligence,
	 faith := Faith}, Connection) ->
    Query = "INSERT INTO lyceum.view_character (name,  e_mail, username, constitution, wisdom, strength, endurance, intelligence, faith) \
             VALUES ($1::VARCHAR(18), $2::TEXT, $3::VARCHAR(32), $4::SMALLINT, $5::SMALLINT, $6::SMALLINT, $7::SMALLINT, $8::SMALLINT, $9::SMALLINT)",
    {ok, _} = epgsql:equery(Connection, Query, [Name, Username, Email, Constitution, Wisdom, Strength, Endurance, Intelligence, Faith]).

%% TODO: Add a Select first in order to check already being activated
activate(#{name := Name, 
	   username := Username, 
	   email := Email},
	   UserPid, Connection) ->
    Query = "INSERT INTO lyceum.active_characters (name,  e_mail, username, user_pid) \
             VALUES ($1::VARCHAR(18), $2::TEXT, $3::VARCHAR(32), $4::VARCHAR(50)) \
             ON CONFLICT (name, username, e_mail) \
             DO UPDATE SET user_pid = $4::VARCHAR(50)",
    {ok, _} = epgsql:equery(Connection, Query, [Name, Email, Username, UserPid]),
    ok.

%% TODO: Add a Select first in order to check already being deactivated
deactivate(UserPid, Connection) ->
    Query = "DELETE FROM lyceum.active_characters \ 
             WHERE user_pid = $1::VARCHAR(50)",
    {ok, _} = epgsql:equery(Connection, Query, [UserPid]),
    ok.

update(#{name := Name, 
	 username := Username, 
	 email := Email,
	 map_name := MapName,
	 x_position := XPosition,
	 y_position := YPosition}, Connection) ->
    Query = "UPDATE lyceum.view_character SET x_position = $1::SMALLINT, y_position = $2::SMALLINT \ 
             WHERE name = $3::VARCHAR(18) AND e_mail = $4::TEXT AND username = $5::VARCHAR(32) AND map_name = $6::VARCHAR(64)",
    {ok, _} = epgsql:equery(Connection, Query, [XPosition, YPosition, Name, Email, Username, MapName]).

updateTemp(#{name := Name, 
	     username := Username, 
	     email := Email,
	     map_name := MapName,
	     face_direction := FaceDirection,
	     x_position := XPosition,
	     y_position := YPosition}, Connection) ->
    %% io:format("x: ~p, y: ~p\n", [XPosition, YPosition]),
    Query = "UPDATE lyceum.character_position SET x_position = $1::SMALLINT, y_position = $2::SMALLINT, face_direction = $7::SMALLINT \ 
             WHERE name = $3::VARCHAR(18) AND e_mail = $4::TEXT AND username = $5::VARCHAR(32) AND map_name = $6::VARCHAR(64)",
    {ok, _} = epgsql:with_transaction(Connection, 
				      fun (Conn) -> epgsql:equery(Conn, Query, [XPosition, YPosition, Name, Email, Username, MapName, FaceDirection]) 
				      end,
				      #{ begin_opts => "ISOLATION LEVEL READ UNCOMMITTED"}),
    ok = epgsql:sync(Connection).


retrieve_near_players(#{map_name := MapName}, UserPid, Connection) ->
    Query = "SELECT lyceum.view_character.name, \
                    lyceum.view_character.constitution, \
                    lyceum.view_character.wisdom, \
                    lyceum.view_character.strength, \
                    lyceum.view_character.endurance, \
                    lyceum.view_character.intelligence, \
                    lyceum.view_character.faith, \
                    lyceum.view_character.x_position, \
                    lyceum.view_character.y_position, \
                    lyceum.view_character.map_name, \
                    lyceum.view_character.face_direction \
             FROM lyceum.view_character \
             NATURAL JOIN lyceum.active_characters \
             WHERE map_name = $1::VARCHAR(64) AND user_pid <> $2::VARCHAR(50)",
    {ok, FullColumns, Values} = epgsql:equery(Connection, Query, [MapName, UserPid]),
    util:columns_and_rows(FullColumns, Values).

retrieve(#{name := Name, 
	   username := Username, 
	   email := Email,
	   map_name := MapName}, Connection) ->
    Query = "SELECT lyceum.view_character.x_position, \
                    lyceum.view_character.y_position  \
             WHERE name = $1::VARCHAR(18), e_mail = $2::TEXT, username = $3::VARCHAR(32), map_name = $4::VARCHAR(64)",
    {ok, FullColumns, Values} = epgsql:equery(Connection, Query, [Name, Email, Username, MapName]),
    util:columns_and_rows(FullColumns, Values).

player_characters(Username, Email, Connection) ->
    Query = "SELECT lyceum.view_character.name, \
                    lyceum.view_character.constitution, \
                    lyceum.view_character.wisdom, \
                    lyceum.view_character.strength, \
                    lyceum.view_character.endurance, \
                    lyceum.view_character.intelligence, \
                    lyceum.view_character.faith, \
                    lyceum.view_character.x_position, \
                    lyceum.view_character.y_position, \
                    lyceum.view_character.map_name, \
                    lyceum.view_character.face_direction \
             FROM lyceum.view_character WHERE username = $1::VARCHAR(32) AND e_mail = $2::TEXT",
    {ok, FullColumns, Values} = epgsql:equery(Connection, Query, [Username, Email]),
    util:columns_and_rows(FullColumns, Values).
    %% io:format("Username: ~p, Email: ~p, Data: ~p\n", [Username, Email, Something]),    

%% INSERT INTO lyceum."view_character"("name", "e-mail", "username", "constitution", "wisdom", "strength", "endurance", "intelligence", "faith")
%% VALUES ('knight', 'test@email.com', 'test', 10, 12, 13, 14, 15, 16);


