const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Router = struct {
    const Self = @This();

    ip: u8,
    mac_address: u8,
    IP_Table: std.ArrayList(u8), // Todo: implement IP Table
    ARP_Table: std.ArrayList(u8), // Todo: implement IP Table

    fn init(self: Self, allocator: Allocator) !void {
        _ = self;
        _ = allocator;
    }

    fn deinit() !void {}
    fn dhcp_offer() !void {}
    fn ARP_request() !void {}
    fn ARP_response() !void {}
    fn route_packet() !void {}
};
