const erl = @import("../erlang.zig");
const rl = @import("raylib");
const messages = @import("../server_messages.zig");
const std = @import("std");
const mainMenu = @import("../menu/main.zig");
const physics = @import("physics.zig");

// TODO: Make this a tagged union in which we have different data available
// per scene, so we can have more guarantees of what is happening with the data
// This should allow us to not have nullables everywhere.
pub const Scene = enum {
    user_registry,
    user_login,
    nothing,
    join,
    spawn,
    character_selection,
    connect,
};

pub const World = struct {
    pub const Character = struct {
        stats: messages.Character_Info = .{},
        model: ?rl.Model = null,
        // TODO: Remove this position and use spatial info from stats
        position: rl.Vector3 = .{
            .x = 0.0,
            .y = physics.character.floorLevel,
            .z = 0.0,
        },
        preview: ?rl.Texture2D = null,
        faceDirection: f32 = 270,
        velocity: rl.Vector3 = .{
            .x = 0,
            .y = 0,
            .z = 0,
        },
    };
    character: Character = .{},
    other_players: []const messages.Character_Info = &.{},
    camera: rl.Camera = undefined,
    cameraDistance: f32 = 60,
};
pub const Connection = struct {
    handler: ?erl.ei.erlang_pid = null,
    node: *erl.Node,
    is_connected: bool = false,
};
// Common
width: f32,
height: f32,
menu: mainMenu.Menu = undefined,
allocator: std.mem.Allocator = std.heap.c_allocator,
scene: Scene = .nothing,
connection: Connection,
world: World = undefined,

pub fn init(width: f32, height: f32, node: *erl.Node) !@This() {
    const camera: rl.Camera = .{
        .position = .{ .x = 50.0, .y = 50.0, .z = 50.0 },
        .target = .{ .x = 0.0, .y = 10.0, .z = 0.0 },
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 45.0,
        .projection = .camera_perspective,
    };
    if (width < 0) return error.negative_width;
    if (height < 0) return error.negative_height;
    return .{ .width = width, .height = height, .connection = .{
        .node = node,
    }, .world = .{
        .camera = camera,
    } };
}
