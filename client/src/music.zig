const rl = @import("raylib");
const std = @import("std");
const GameState = @import("game/state.zig");

const Action_Kind = enum {
    toggle,
    restart,
    increase_volume,
    decrease_volume,
    mute,
};

const Action = struct {
    kind: Action_Kind,
    key: rl.KeyboardKey,
};

const availableActions = [_]Action{
    .{ .key = .key_m, .kind = .mute },
    .{ .key = .key_n, .kind = .restart },
    .{ .key = .key_p, .kind = .toggle },
    .{ .key = .key_comma, .kind = .decrease_volume },
    .{ .key = .key_period, .kind = .increase_volume },
};

pub fn play(gameState: *GameState) void {
    if (gameState.music.playing) {
        std.debug.print("I should be playing\n", .{});
        rl.setMusicVolume(gameState.menu.assets.music, gameState.music.volume);
        rl.updateMusicStream(gameState.menu.assets.music);
    }
}

fn toggle(gameState: *GameState) void {
    if (gameState.music.playing) {
        rl.pauseMusicStream(gameState.menu.assets.music);
        gameState.music.playing = false;
    } else {
        rl.resumeMusicStream(gameState.menu.assets.music);
        gameState.music.playing = true;
    }
}

pub fn control(gameState: *GameState) void {
    for (availableActions) |action| {
        if (rl.isKeyDown(action.key)) {
            switch (action.kind) {
                .restart => {
                    rl.stopMusicStream(gameState.menu.assets.music);
                    rl.playMusicStream(gameState.menu.assets.music);
                },
                .mute => {
                    gameState.music.volume = 0;
                },
                .toggle => {
                    toggle(gameState);
                },
                .increase_volume => {
                    gameState.music.volume += 0.1;
                },
                .decrease_volume => {
                    gameState.music.volume -= 0.1;
                },
            }
        }
    }
}
