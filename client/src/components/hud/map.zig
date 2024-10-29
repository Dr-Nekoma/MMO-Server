const common = @import("common.zig");
const config = @import("../../config.zig");
const rl = @import("raylib");
const rm = rl.math;
const std = @import("std");
const GameState = @import("../../game/state.zig");

pub fn init_map_texture() rl.Texture {
    const side = config.map.border_thickness * 2;
    const img = rl.genImageColor(side, side, rl.Color.black);
    defer img.unload();
    return img.toTexture();
}

fn rotate_point(
    position: rl.Vector2,
    origin: rl.Vector2,
    degrees: f32,
) rl.Vector2 {
    const radians = degrees * (std.math.pi / 180.0);
    const dx = position.x - origin.x;
    const dy = position.y - origin.y;
    return .{
        .x = origin.x + dx * @cos(radians) - dy * @sin(radians),
        .y = origin.y + dx * @sin(radians) + dy * @cos(radians),
    };
}

pub fn add_borders(image: *rl.Image) void {
    const thickness = config.map.border_thickness;
    const width = image.width + 2 * thickness;
    const height = image.height + 2 * thickness;
    return image.resizeCanvas(width, height, thickness, thickness, rl.Color.black);
}

pub fn at(character: *const GameState.World.Character, width: f32, height: f32) !void {
    const face_direction: f32 = @floatFromInt(@abs(270 - character.stats.face_direction));
    const character_x: f32 = rm.clamp(-character.stats.y_position, 0, config.map.max_width);
    const character_y: f32 = rm.clamp(character.stats.x_position, 0, config.map.max_height);
    const outerRadius = config.map.border_thickness;
    const innerRadius = outerRadius - 10;
    const map_image = character.inventory.hud.map.?;

    const origin = .{ .x = 0, .y = 0 };
    const triangle_top = rotate_point(.{ .y = -8, .x = 0 }, origin, face_direction);
    const triangle_left = rotate_point(.{ .y = 4, .x = -4 }, origin, face_direction);
    const triangle_right = rotate_point(.{ .y = 4, .x = 4 }, origin, face_direction);

    const center: rl.Vector2 = .{
        .x = width - innerRadius - innerRadius / 2,
        .y = height - innerRadius - 20,
    };

    const normalized_x = character_x * @as(
        f32,
        @as(f32, @floatFromInt(map_image.width - 2 * config.map.border_thickness)) /
            @as(f32, @floatFromInt(config.map.max_width)),
    );
    const normalized_y = character_y * @as(
        f32,
        @as(f32, @floatFromInt(map_image.height - 2 * config.map.border_thickness)) /
            @as(f32, @floatFromInt(config.map.max_height)),
    );
    const map_x = center.x - outerRadius;
    const map_y = center.y - outerRadius;
    const map_mask = rl.Rectangle{
        .x = normalized_x,
        .y = normalized_y,
        .width = @floatFromInt(@min(outerRadius * 2, map_image.width)),
        .height = @floatFromInt(@min(outerRadius * 2, map_image.height)),
    };
    var map = rl.imageFromImage(character.inventory.hud.map.?, map_mask);
    defer map.unload();

    var alpha_mask = rl.genImageColor(
        @intFromFloat(map_mask.width),
        @intFromFloat(map_mask.height),
        rl.Color.black,
    );
    defer alpha_mask.unload();

    alpha_mask.drawCircle(
        outerRadius,
        outerRadius,
        innerRadius,
        rl.Color.white,
    );
    map.alphaMask(alpha_mask);

    const pixels = try rl.loadImageColors(map);
    const texture = character.inventory.hud.texture.?;
    rl.updateTexture(texture, pixels.ptr);

    texture.draw(@intFromFloat(map_x), @intFromFloat(map_y), rl.Color.white);
    rl.drawRing(center, innerRadius, outerRadius, 0, 360, 0, config.ColorPalette.primary);
    rl.drawCircleLinesV(center, innerRadius, rl.Color.white);
    rl.drawCircleLinesV(center, innerRadius - 1, rl.Color.white);
    rl.drawTriangle(
        center.add(triangle_top),
        center.add(triangle_left),
        center.add(triangle_right),
        rl.Color.white,
    );
}
