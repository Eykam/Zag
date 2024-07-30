const std = @import("std");
const Frame_Handler = @import("./Frame.zig");
const MAC = @import("./MAC.zig");
const NAT = @import("./NAT.zig");

const Allocator = std.mem.Allocator;
const Frame = Frame_Handler;
const Eth_Frame = Frame.Eth_Frame;

// const IpAddress = ?[4]u8;

const EtherType = enum(u16) {
    IPv4 = 0x0800,
    ARP = 0x0806,
};

const Interface = struct {
    const Self = @This();

    name: []const u8,
    mac: MAC.MAC_Address,
    NAT_Table: NAT.NAT_Table, // table to keep track of open file descriptors and their bindings (IP:Port)
    gateway: [4]u8,

    pub fn init(
        allocator: Allocator,
        name: []const u8,
    ) !Interface {
        return Interface{
            .name = name,
            .mac = Self.generate_mac_address(),
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

    fn generate_mac_address(self: *Interface) !MAC.MAC_Address {
        _ = self;

        const rnd = std.Random.DefaultPrng.init(std.time.nanoTimestamp());
        return try std.Random.int(rnd, u48);
    }

    fn log() void {}
};

test "interface_generate_mac_address" {}

test "interface_send_frame" {}

test "interface_forward_to_binding" {}
