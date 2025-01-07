const assets = @import("../assets.zig");
const chat = @import("../components/hud/Chat.zig");
const config = @import("../config.zig");
const errorC = @import("../components/error.zig");
const hud = @import("../components/hud/main.zig");
const items = @import("items/main.zig");
const mainMenu = @import("../menu/main.zig");
const map = @import("../components/hud/map.zig");
const messages = @import("../server/messages.zig");
const physics = @import("physics.zig");
const rl = @import("raylib");
const std = @import("std");
const zerl = @import("zerl");
const Button = @import("../components/button.zig");

    pub const Chat = struct {
        pub const bufferSize = 50;
        content: [bufferSize:0]u8 = .{0} ** bufferSize,
        messages: std.ArrayList(chat.Message) = std.ArrayList(chat.Message).init(std.heap.c_allocator),
        position: usize = 0,
        mode: chat.Mode = .idle,
    };

pub const Animation = struct {
    pub const State = enum {
        walking,
        idle,
    };
    frameCounter: i32 = 0,
    frames: []rl.ModelAnimation = &.{},
};

animation: Animation = .{},
stats: messages.Character_Info = .{},
model: ?rl.Model = null,
// TODO: Remove this position and use spatial info from stats
position: rl.Vector3 = .{
    .x = 0.0,
    .y = physics.character.floorLevel,
    .z = 0.0,
},
preview: ?rl.Texture2D = null,
velocity: rl.Vector3 = .{
    .x = 0,
    .y = 0,
    .z = 0,
},
// TODO: These things should come from the server
inventory: struct {
    items: []const items.Entity = &.{},
    spells: []const [:0]const u8 = &.{},
    hud: struct {
        spells: []const [:0]const u8 = &.{},
        consumables: []const [:0]const u8 = &.{},
        minimap: struct {
            map: ?rl.Image = null,
            texture: ?rl.Texture = null,
        } = .{},
        chat: Chat = .{},
    } = .{},
} = .{},
