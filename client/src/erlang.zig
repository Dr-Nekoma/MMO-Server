pub const ei = @cImport({
    @cInclude("ei.h");
});

const std = @import("std");
const receiver = @import("erlang/receiver.zig");
const sender = @import("erlang/sender.zig");

// TODO: move these elsewhere, maybe make them into parameters
pub const process_name = "lyceum_server";
pub const server_name = process_name ++ "@179.237.195.222";

pub fn print_connect_server_error(message: anytype) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(
        "Could not connect to Lyceum Server!\n\u{1b}[31mError: \u{1b}[37m{}\n",
        .{message},
    );
}

pub const Send_Error = sender.Error || error{
    // TODO: rid the world of these terrible names
    new_with_version,
    reg_send_failed_to_subprocess,
    reg_send_failed_to_master,
};

pub const Node = struct {
    c_node: ei.ei_cnode,
    fd: i32,
    node_name: [:0]const u8 = "lyceum_client",
    cookie: [:0]const u8 = "lyceum",
    handler: ?ei.erlang_pid = null,

    pub fn receive(ec: *Node, comptime T: type, allocator: std.mem.Allocator) !T {
        return receiver.run(T, allocator, ec);
    }

    pub fn send(ec: *Node, data: anytype) Send_Error!void {
        var buf: ei.ei_x_buff = undefined;
        // TODO: get rid of hidden allocation
        try validate(error.new_with_version, ei.ei_x_new_with_version(&buf));
        defer _ = ei.ei_x_free(&buf);

        try sender.send_payload(&buf, data);
        if (ec.handler) |*pid| {
            try validate(
                error.reg_send_failed_to_subprocess,
                ei.ei_send(ec.fd, pid, buf.buff, buf.index),
            );
        } else {
            try validate(
                error.reg_send_failed_to_master,
                ei.ei_reg_send(&ec.c_node, ec.fd, @constCast(process_name), buf.buff, buf.index),
            );
        }
    }

    pub fn self(ec: *Node) !*ei.erlang_pid {
        return if (ei.ei_self(&ec.c_node)) |pid|
            pid
        else
            error.could_not_find_self;
    }
};

pub fn validate(error_tag: anytype, result_value: c_int) !void {
    if (result_value < 0) {
        return error_tag;
    }
}

const max_size = 50;

pub fn establish_connection(ec: *Node, ip: []const u8) !void {
    var buffer: [max_size:0]u8 = .{0} ** max_size;
    std.mem.copyForwards(u8, &buffer, process_name);
    buffer[process_name.len] = '@';
    std.mem.copyForwards(u8, buffer[process_name.len + 1 ..], ip);
    const sockfd = ei.ei_connect(&ec.c_node, &buffer);
    try validate(error.ei_connect_failed, sockfd);
    ec.fd = sockfd;
}

pub fn prepare_connection() !Node {
    var l_node: Node = .{
        .c_node = undefined,
        .fd = undefined,
    };
    const creation = std.time.timestamp() + 1;
    const creation_u: u64 = @bitCast(creation);
    const result = ei.ei_connect_init(
        &l_node.c_node,
        l_node.node_name.ptr,
        l_node.cookie.ptr,
        @truncate(creation_u),
    );
    return if (result < 0)
        error.ei_connect_init_failed
    else
        l_node;
}

pub fn With_Pid(comptime T: type) type {
    return std.meta.Tuple(&.{ ei.erlang_pid, T });
}
