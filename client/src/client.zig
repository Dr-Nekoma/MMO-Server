const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");
const state = @import("game/state.zig");
const user = @import("menu/user.zig");
const character = @import("menu/character.zig");
const mainMenu = @import("menu/main.zig");
const connection = @import("menu/connection.zig");
const game = @import("game/main.zig");

pub fn main() anyerror!void {
    var gameState = try state.init(800, 450);
    gameState.menu = .{ .character_name = try gameState.allocator.allocSentinel(u8, config.nameSize, 0) };
    @memset(gameState.menu.character_name, 0);

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(@intFromFloat(gameState.width), @intFromFloat(gameState.height), "Lyceum");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    // try character.goToSpawn(&gameState);
    mainMenu.spawn(&gameState);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(config.ColorPalette.background);
        gameState.width = @floatFromInt(rl.getScreenWidth());
        gameState.height = @floatFromInt(rl.getScreenHeight());

        switch (gameState.scene) {
            .user_registry => {
                rl.openURL("https://github.com/Dr-Nekoma/lyceum");
                gameState.scene = .nothing;
            },
            .user_login => {
                try user.login(&gameState);
            },
            .join => {
                try character.join(&gameState);
            },
            .spawn => {
                try game.spawn(&gameState);
            },
            .character_selection => {
                try character.selection(&gameState);
            },
            .connect => {
                try connection.connect(&gameState);
            },
            .nothing => {
                mainMenu.spawn(&gameState);
            },
        }
    }
}
