-module(character).

-export([create/2, player_characters/2, player_character/2, update/2, retrieve_near_players/2, activate/2, deactivate/4]).

create(#{name := Name, 
	 username := Username, 
	 email := Email,
	 constitution := Constitution,
	 wisdom := Wisdom,
	 strength := Strength,
	 endurance := Endurance,
	 intelligence := Intelligence,
	 faith := Faith}, Connection) ->
    Query = "INSERT INTO character.view (name,  e_mail, username, constitution, wisdom, strength, endurance, intelligence, faith) \
             VALUES ($1::VARCHAR(18), $2::TEXT, $3::VARCHAR(32), $4::SMALLINT, $5::SMALLINT, $6::SMALLINT, $7::SMALLINT, $8::SMALLINT, $9::SMALLINT)",
    Result = epgsql:equery(Connection, Query, [Name, Username, Email, Constitution, Wisdom, Strength, Endurance, Intelligence, Faith]),
    Fun = (fun (_, _, _) -> ok end),
    database_utils:process_postgres_result(Result, insert, Fun).

%% TODO: Add a Select first in order to check already being activated
activate(#{name := Name, 
	   username := Username, 
	   email := Email},
	   Connection) ->
    Query = "INSERT INTO character.active (name,  e_mail, username) \
             VALUES ($1::VARCHAR(18), $2::TEXT, $3::VARCHAR(32))",
    Result = epgsql:equery(Connection, Query, [Name, Email, Username]),
    Fun = (fun (_) -> ok end),
    database_utils:process_postgres_result(Result, insert, Fun).

%% TODO: Add a Select first in order to check already being deactivated
deactivate(Name, Email, Username, Connection) ->
    Query = "DELETE FROM character.active \ 
             WHERE name = $1::VARCHAR(18) AND e_mail = $2::TEXT AND username = $3::VARCHAR(32)",
    Result = epgsql:equery(Connection, Query, [Name, Email, Username]),
    Fun = (fun (_) -> ok end),
    database_utils:process_postgres_result(Result, delete, Fun).

update(#{name := Name, 
	 username := Username, 
	 email := Email,
	 map_name := MapName,
	 face_direction := FaceDirection,
	 state_type := StateType,
	 x_position := XPosition,
	 y_position := YPosition,
	 x_velocity := XVelocity,
	 y_velocity := YVelocity,
	 level := Level,
	 health := Health,
	 mana := Mana}, Connection) ->
    %% io:format("x: ~p, y: ~p, state_type: ~p\n", [XVelocity, YVelocity, StateType]),
    Query = "UPDATE character.view SET x_position = $1::REAL, y_position = $2::REAL, \
             x_velocity = $3::REAL, y_velocity = $4::REAL, level = $5::SMALLINT, health = $6::SMALLINT, mana = $7::SMALLINT, \
             face_direction = $8::SMALLINT, state_type = $9::\"character\".STATE_TYPE \ 
             WHERE name = $10::VARCHAR(18) AND e_mail = $11::TEXT AND username = $12::VARCHAR(32) AND map_name = $13::VARCHAR(64)",
    Result = epgsql:with_transaction(Connection, 
				      fun (Conn) -> 
					      epgsql:equery(Conn, Query, 
							    [XPosition, YPosition, XVelocity, YVelocity, Level, Health, Mana, FaceDirection, StateType, Name, Email, Username, MapName])
				      end,
				      #{ begin_opts => "ISOLATION LEVEL READ UNCOMMITTED"}),
    Fun = (fun (_) -> epgsql:sync(Connection) end),
    database_utils:process_postgres_result(Result, update, Fun).

retrieve_near_players(#{map_name := MapName, name := Name}, Connection) ->
    Query = "SELECT character.view.name, \
                    character.view.constitution, \
                    character.view.wisdom, \
                    character.view.strength, \
                    character.view.endurance, \
                    character.view.intelligence, \
                    character.view.faith, \
                    character.view.x_position, \
                    character.view.y_position, \
                    character.view.x_velocity, \
                    character.view.y_velocity, \
                    character.view.map_name, \
                    character.view.face_direction, \
                    character.view.level, \
                    character.view.health_max, \
                    character.view.health, \
                    character.view.mana_max, \
                    character.view.mana, \
                    character.view.state_type \
             FROM character.view \
             NATURAL JOIN character.active \
             WHERE map_name = $1::VARCHAR(64) AND name <> $2::VARCHAR(18)",
    Result = epgsql:equery(Connection, Query, [MapName, Name]),
    Fun = (fun (FullColumns, Values) -> {ok, database_utils:transform_character_map(database_utils:columns_and_rows(FullColumns, Values))} end),
    database_utils:process_postgres_result(Result, select, Fun).

player_characters(#{username := Username, 
		    email := Email}, Connection) ->
    Query = "SELECT character.view.name, \
                    character.view.constitution, \
                    character.view.wisdom, \
                    character.view.strength, \
                    character.view.endurance, \
                    character.view.intelligence, \
                    character.view.faith, \
                    character.view.x_position, \
                    character.view.y_position, \
                    character.view.x_velocity, \
                    character.view.y_velocity, \
                    character.view.map_name, \
                    character.view.face_direction, \
                    character.view.level, \
                    character.view.health_max, \
                    character.view.health, \
                    character.view.mana_max, \
                    character.view.mana, \
                    character.view.state_type \
             FROM character.view WHERE username = $1::VARCHAR(32) AND e_mail = $2::TEXT",
    Result = epgsql:equery(Connection, Query, [Username, Email]),
    Fun = (fun (FullColumns, Values) -> {ok, database_utils:transform_character_map(database_utils:columns_and_rows(FullColumns, Values))} end),
    database_utils:process_postgres_result(Result, select, Fun).
    %% io:format("Username: ~p, Email: ~p, Data: ~p\n", [Username, Email, Something]),    


player_character(#{name := Name, 
		   username := Username, 
		   email := Email}, Connection) ->
    Query = "SELECT character.view.constitution, \
                    character.view.wisdom, \
                    character.view.strength, \
                    character.view.endurance, \
                    character.view.intelligence, \
                    character.view.faith, \
                    character.view.x_position, \
                    character.view.y_position, \
                    character.view.map_name, \
                    character.view.face_direction, \
                    character.view.level, \
                    character.view.health_max, \
                    character.view.health, \
                    character.view.mana_max, \
                    character.view.mana, \
                    character.view.state_type \
             FROM character.view WHERE username = $1::VARCHAR(32) AND e_mail = $2::TEXT AND name = $3::TEXT",
    Result = epgsql:equery(Connection, Query, [Username, Email, Name]),
    Fun = (fun (FullColumns, Values) -> 
		   case database_utils:transform_character_map(database_utils:columns_and_rows(FullColumns, Values)) of
		       [C|[]] -> {ok, C};
		       [] -> {error, "Updated Character not found!"};
		       _ -> {error, "Found more than one Character!"}
		   end
	   end),
    database_utils:process_postgres_result(Result, select, Fun).
    %% io:format("Username: ~p, Email: ~p, Data: ~p\n", [Username, Email, Something]),    