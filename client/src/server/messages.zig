const rl = @import("raylib");
const std = @import("std");
const zerl = @import("zerl");
const GameState = @import("../game/state.zig");
const GameCharacter = @import("../game/character.zig");

fn createAnonymousStruct(comptime T: type, comptime keys: []const [:0]const u8) type {
    const struct_info = @typeInfo(T).Struct;
    comptime var structKeys: [keys.len]std.meta.Tuple(&.{[:0]const u8}) = undefined;
    comptime for (0.., keys) |index, key| {
        structKeys[index] = .{key};
    };
    const mapKeys = std.StaticStringMap(void).initComptime(structKeys);
    return comptime blk: {
        var fields: [keys.len]std.builtin.Type.StructField = undefined;
        var fieldsCounter: usize = 0;
        for (struct_info.fields) |field| {
            if (mapKeys.has(field.name)) {
                fields[fieldsCounter] = field;
                fieldsCounter += 1;
            }
        }
        break :blk @Type(.{
            .Struct = .{
                .layout = .auto,
                .fields = &fields,
                .decls = &[_]std.builtin.Type.Declaration{},
                .is_tuple = false,
            },
        });
    };
}

pub fn selectKeysFromStruct(data: anytype, comptime keys: []const [:0]const u8) createAnonymousStruct(@TypeOf(data), keys) {
    const Temp: type = createAnonymousStruct(@TypeOf(data), keys);
    var anonymousStruct: Temp = undefined;
    inline for (@typeInfo(Temp).Struct.fields) |field| {
        const current_field = &@field(anonymousStruct, field.name);
        current_field.* = @field(data, field.name);
    }
    return anonymousStruct;
}

// Standard Response from Erlang Server

fn Tuple_Response(comptime T: type) type {
    return union(enum) {
        ok: T,
        @"error": [:0]const u8,
    };
}

pub const Erlang_Response = Tuple_Response(void);

// User's Login and Registration

pub const Login_Request = struct {
    username: []const u8,
    password: []const u8,
};

const Login_Info = std.meta.Tuple(&.{ zerl.ei.erlang_pid, [:0]const u8 });
pub const Login_Response = Tuple_Response(Login_Info);

pub const Registry_Request = struct {
    username: [:0]const u8,
    email: [:0]const u8,
    password: [:0]const u8,
};

// TODO: Implement user registration via the client
pub const Registry_Response = Tuple_Response(void);

// User's Characters

pub const Character_Info = struct {
    level: u8 = 0,
    health: u16 = 0,
    health_max: u16 = 100,
    mana: u16 = 0,
    mana_max: u16 = 100,
    name: [:0]const u8 = "",
    constitution: u8 = 0,
    wisdom: u8 = 0,
    endurance: u8 = 0,
    strength: u8 = 0,
    intelligence: u8 = 0,
    faith: u8 = 0,
    x_position: f32 = 0,
    y_position: f32 = 0,
    x_velocity: f32 = 0,
    y_velocity: f32 = 0,
    face_direction: i16 = 270,
    map_name: [:0]const u8 = "",
    state_type: GameCharacter.Animation.State = .idle,
};

pub const Characters_Request = struct {
    username: []const u8,
    email: []const u8,
};

pub const Characters_Response = Tuple_Response([]const Character_Info);

pub const Character_Join = struct {
    username: []const u8,
    name: []const u8,
    email: []const u8,
    map_name: []const u8,
};

pub const Tile = enum {
    empty,
    water,
    grass,
    sand,
    dirt,
};

pub const Object = enum {
    empty,
    bush,
    tree,
    chest,
    rock,
};

pub const Position = [2]f32;

pub const Resource =
    struct {
    kind: Object = .empty,
    quantity: u32 = 50,
    capacity: u32 = 50,
    base_extraction_amount: u32 = 1,
    base_extraction_time: u32 = 1,
};

pub const ResourceLocation = struct { Position, Resource };

pub const Map = struct {
    width: u32 = 10,
    height: u32 = 10,
    tiles: []const Tile = &.{},
    objects: []const Object = &.{},
    resources: []const ResourceLocation = &.{},
};

pub const Character_Join_Info = struct {
    character: Character_Info,
    map: Map,
};
pub const Character_Join_Response = Tuple_Response(Character_Join_Info);

pub const Character_Update = struct {
    level: u8,
    health: u16,
    mana: u16,
    name: [:0]const u8,
    x_position: f32,
    y_position: f32,
    x_velocity: f32,
    y_velocity: f32,
    map_name: [:0]const u8,
    username: []const u8,
    face_direction: i16,
    email: []const u8,
    state_type: GameCharacter.Animation.State,
};

// Central place to send game's data

pub const Payload = union(enum) {
    debug: [:0]const u8,
    exit_map: void,
    joining_map: Character_Join,
    list_characters: Characters_Request,
    login: Login_Request,
    logout: void,
    register: Registry_Request,
    // create_character:
    update_character: Character_Update,
};
