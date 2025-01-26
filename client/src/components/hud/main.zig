const chat = @import("Chat.zig");
const config = @import("../../config.zig");
const spells = @import("spells.zig");
const map = @import("map.zig");
const consumables = @import("consumables.zig");
const info = @import("info.zig");
const GameState = @import("../../game/state.zig");
const resources = @import("resources.zig");
const rl = @import("raylib");
const rm = rl.math;
const std = @import("std");

fn drawPlayers(gameState: *GameState) !void {
    const mainPlayer = &gameState.world.character;
    var player_iterator = gameState.world.other_players.valueIterator();
    while (player_iterator.next()) |player| {
        if (GameState.canDisplayPlayer(mainPlayer, player)) {
            var infoPosition = rl.getWorldToScreen(player.position, gameState.world.camera);
            infoPosition.y += 30;
            const fontSize = 15;
            try info.stats(player, info.mainSize, infoPosition, fontSize, gameState.allocator, &gameState.menu.assets.font);
        }
        const character = gameState.world.character;
        const map_image = gameState.world.character.inventory.hud.minimap.map.?;
        const c_x, const c_y = map.coordinates.normalize(.{
            .x = character.stats.x_position,
            .y = character.stats.y_position,
        }, &map_image, &gameState.world.map);
        const p_x, const p_y = map.coordinates.normalize(.{
            .x = player.stats.x_position,
            .y = player.stats.y_position,
        }, &map_image, &gameState.world.map);
        const delta: rl.Vector2 = .{
            .x = p_x - c_x,
            .y = p_y - c_y,
        };
        if (delta.length() < map.innerRadius) {
            const center: rl.Vector2 = map.getCenter(gameState.width, gameState.height).add(delta);
            map.player(player.stats.face_direction, center);
        }
    }
}

fn detectResource(gameState: *GameState, tx: i32, ty: i32, angle: i16) void {
    const width = gameState.width;
    const height = gameState.height;
    const world = &gameState.world.map;
    const font = &gameState.menu.assets.font;

    const iwidth: i32 = @intCast(world.instance.width);
    const iheight: i32 = @intCast(world.instance.height);

    const x = std.math.clamp(tx, 0, iwidth);
    const y = std.math.clamp(ty, 0, iheight);

    const entity = &gameState.world.character;
    if (world.resources.get(.{ @floatFromInt(x), @floatFromInt(y) })) |resource| {
        if (resource.quantity > 0 and entity.stats.face_direction == angle) {
            // TODO: If the server sends a non-client-supported asset, this will explode
            const value = resources.info.get(@tagName(resource.kind)).?;
            value.drawer(width, height, font);
            if (rl.isKeyPressed(value.key)) {
                std.debug.print("Detected Resource! It is: .{}\n", .{resource.kind});
            }
        }
    }
}

fn detectResources(gameState: *GameState) void {
    const player = &gameState.world.character;

    if (player.inventory.hud.chat.mode == .writing) return;

    const x_tile: i32 = @intFromFloat(player.position.x / config.assets.tile.size);
    const y_tile: i32 = @intFromFloat(player.position.z / config.assets.tile.size);

    detectResource(gameState, x_tile, y_tile + 1, 0);
    detectResource(gameState, x_tile + 1, y_tile, 90);
    detectResource(gameState, x_tile, y_tile - 1, 180);
    detectResource(gameState, x_tile - 1, y_tile, 270);
}

pub fn at(gameState: *GameState) !void {
    const width = gameState.width;
    const height = gameState.height;
    const character = &gameState.world.character;

    try spells.at(character.inventory.hud.spells, width, height, &gameState.menu.assets.font);

    try consumables.at(character.inventory.hud.consumables, height, &gameState.menu.assets.font);

    const mainPosition: rl.Vector2 = .{
        .x = width / 2,
        .y = 18,
    };

    try info.at(character, info.mainSize, mainPosition, config.textFontSize, gameState.allocator, &gameState.menu.assets.font);

    try map.at(character, &gameState.world.map, width, height, &gameState.menu.assets.font);

    const chatC = chat{
        .content = &character.inventory.hud.chat.content,
        .position = &character.inventory.hud.chat.position,
        .messages = &character.inventory.hud.chat.messages,
        .mode = &character.inventory.hud.chat.mode,
    };
    try chatC.at(character.stats.name, gameState);

    // TODO: This should be at the beginning, but mini-map screw us over.
    // Putting this on the top makes the other players pointers disappear.
    try drawPlayers(gameState);
    detectResources(gameState);
}
