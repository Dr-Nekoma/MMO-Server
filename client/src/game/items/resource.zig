const messages = @import("../../server/messages.zig");

pub const Entity = union(messages.Object) {
    empty: void,
    bush: u8,
    tree: u8,
    chest: u8,
    rock: u8,
};
