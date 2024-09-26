const std = @import("std");
const MAC = @import("MAC.zig");
const NAT = @import("NAT.zig");

const fs = std.fs;
const mem = std.mem;
const print = std.debug.print;

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

pub fn print_mac_address(mac: MAC.MAC_Address) void {
    print("Mac Address: {}\n", .{mac.address});
}

pub fn print_NAT_Table(nat_list: NAT.NAT_List) void {
    print("\n=========================================== NAT Table ===========================================\n", .{});
    print("{s:16}", .{"Internal IP"});
    print("{s:16}", .{"Internal Port"});

    print("{s:16}", .{"External IP"});
    print("{s:16}", .{"External Port"});

    print("{s:16}", .{"Dest IP"});
    print("{s:16}\n", .{"Dest Port"});

    print("\n=================================================================================================\n", .{});

    for (nat_list.items) |entry| {
        print("{}{s}", .{ entry.internal_IP, " " ** 8 });
        print("{}{s}", .{ entry.internal_port, " " ** 8 });

        print("{}{s}", .{ entry.external_IP, " " ** 8 });
        print("{}{s}", .{ entry.external_port, " " ** 8 });

        print("{}{s}", .{ entry.dest_IP, " " ** 8 });
        print("{}{s}\n", .{ entry.dest_port, " " ** 8 });
    }
}
test "get_mac_addr" {}
