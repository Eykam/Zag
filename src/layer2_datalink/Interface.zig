const std = @import("std");
const Frame_Handler = @import("./Frame.zig");

const Allocator = std.mem.Allocator;
const Frame = Frame_Handler;
const Eth_Frame = Frame.Eth_Frame;

const MacAddress = [6]u8;
// const IpAddress = ?[4]u8;

const EtherType = enum(u16) {
    IPv4 = 0x0800,
    ARP = 0x0806,
};

const Interface = struct {
    name: []const u8,
    mac: MacAddress,
    file_descriptor_table: std.ArrayList(u8), // table to keep track of open file descriptors and their bindings (IP:Port)

    pub fn init(
        allocator: Allocator,
        name: []const u8,
    ) !Interface {
        return Interface{
            .name = name,
            .mac = generate_mac_address(),
            .allocator = allocator,
        };
    }

    pub fn send_frame(self: *Interface, frame: Frame) void {
        _ = self;
        _ = frame;
    }

    // Parse Frame here
    // Get IP & Port or other info if not IP protocol
    // forward traffic to corresponding binding (IP:Port) or proto
    pub fn forward_to_binding(self: *Interface, frame: Frame) !void {
        _ = self;
        _ = frame;
    }

    fn generate_mac_address(self: *Interface) !MacAddress {
        _ = self;

        const rnd = std.Random.DefaultPrng.init(std.time.nanoTimestamp());
        return try std.Random.int(rnd, u48);
    }

    fn log() void {}
};
