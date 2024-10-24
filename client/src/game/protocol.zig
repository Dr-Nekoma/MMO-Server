const assets = @import("../assets.zig");
const messages = @import("../server_messages.zig");
const physics = @import("physics.zig");
const rl = @import("raylib");
const std = @import("std");
const GameState = @import("../game/state.zig");

pub fn pingUpdateCharacter(gameState: *GameState) !void {
    // TODO: We should a time out functionality (Zerl should provide one) to correctly assess
    // if we are not overwhelming the database
    try gameState.send(messages.Payload{
        .update_character = .{
            .name = gameState.world.character.stats.name,
            .x_position = gameState.world.character.stats.x_position,
            .y_position = gameState.world.character.stats.y_position,
            .x_velocity = gameState.world.character.stats.x_velocity,
            .y_velocity = gameState.world.character.stats.y_velocity,
            .map_name = gameState.world.character.stats.map_name,
            .face_direction = gameState.world.character.stats.face_direction,
            .state_type = gameState.world.character.stats.state_type,
            .username = gameState.menu.credentials.username[0..gameState.menu.credentials.usernamePosition],
            .email = gameState.menu.credentials.email,
        },
    });
    const node = gameState.connection.node;
    const server_response = try messages.receive_characters_list(gameState.allocator, node);
    switch (server_response) {
        .ok => |players| {
            const other_players = &gameState.world.other_players;
            for (players) |player| {
                if (other_players.get(player.name)) |current_player| {
                    var next_player = current_player;
                    next_player.stats = player;
                    next_player.position = .{
                        .x = player.x_position,
                        .y = next_player.position.y,
                        .z = player.y_position,
                    };
                    next_player.velocity = .{
                        .x = player.x_velocity,
                        .y = next_player.velocity.y,
                        .z = player.y_velocity,
                    };
                    other_players.putAssumeCapacity(player.name, next_player);
                } else {
                    const new_character = GameState.World.Character{
                        .position = .{
                            .x = player.x_position,
                            .y = physics.character.floorLevel,
                            .z = player.y_position,
                        },
                        .velocity = .{
                            .x = player.x_velocity,
                            .y = 0,
                            .z = player.y_velocity,
                        },
                        .stats = player,
                        .model = try assets.model("walker.m3d"),
                        .animation = .{
                            // We can do this because all players use the same model + animations for now
                            .frames = gameState.world.character.animation.frames,
                        },
                    };
                    try other_players.put(player.name, new_character);
                }
            }
        },
        .@"error" => |msg| {
            defer gameState.allocator.free(msg);
            std.debug.print("[ERROR]: {s}\n", .{msg});
            gameState.scene = .nothing;
        },
    }
}

pub fn pingJoinMap(gameState: *GameState) !void {
    // TODO: We should a time out functionality (Zerl should provide one) to correctly assess
    // if we are not overwhelming the database
    try gameState.send(messages.Payload{
        .joining_map = .{
            .name = gameState.world.character.stats.name,
            .x_position = gameState.world.character.stats.x_position,
            .y_position = gameState.world.character.stats.y_position,
            .x_velocity = gameState.world.character.stats.x_velocity,
            .y_velocity = gameState.world.character.stats.y_velocity,
            .state_type = gameState.world.character.stats.state_type,
            .map_name = gameState.world.character.stats.map_name,
            .face_direction = gameState.world.character.stats.face_direction,
            .username = gameState.menu.credentials.username[0..gameState.menu.credentials.usernamePosition],
            .email = gameState.menu.credentials.email,
        },
    });
    const node = gameState.connection.node;
    const server_response = try messages.receive_standard_response(gameState.allocator, node);
    switch (server_response) {
        .ok => {},
        .@"error" => |msg| {
            defer gameState.allocator.free(msg);
            std.debug.print("[ERROR]: {s}\n", .{msg});
            gameState.scene = .nothing;
        },
    }
}

pub fn pingExitMap(gameState: *GameState) !void {
    // TODO: We should a time out functionality (Zerl should provide one) to correctly assess
    // if we are not overwhelming the database
    try gameState.send(messages.Payload.exit_map);
    const node = gameState.connection.node;
    const server_response = try messages.receive_standard_response(gameState.allocator, node);
    switch (server_response) {
        .ok => {},
        .@"error" => |msg| {
            defer gameState.allocator.free(msg);
            std.debug.print("[ERROR]: {s}\n", .{msg});
            gameState.scene = .nothing;
        },
    }
}
