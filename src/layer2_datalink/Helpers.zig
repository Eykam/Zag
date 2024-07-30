const std = @import("std");
const fs = std.fs;
const mem = std.mem;

pub fn getMacAddress(interface: []const u8) !([8]u8) {
    var path_buffer: [64]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buffer, "/sys/class/net/{s}/address", .{interface});

    const file = try fs.openFileAbsolute(path, .{});
    defer file.close();

    var buf: [18]u8 = undefined; // MAC address is 17 chars + newline
    const bytes_read = try file.readAll(&buf);
    if (bytes_read < 17) return error.InvalidMacAddress;

    var mac: [8]u8 = [_]u8{0} ** 8;
    var mac_parts = mem.splitSequence(u8, buf[0..17], ":");
    var i: usize = 0;
    while (mac_parts.next()) |part| : (i += 1) {
        if (i >= 8) return error.InvalidMacAddress;
        mac[i] = try std.fmt.parseInt(u8, part, 16);
    }

    return mac;
}

test "get_mac_addr" {}
