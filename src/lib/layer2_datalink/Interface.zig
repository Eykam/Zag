const std = @import("std");
const Frame_Handler = @import("Frame.zig");
const MAC = @import("MAC.zig");
const NAT = @import("NAT.zig");
const Switch_Handler = @import("Switch.zig");
const Helpers = @import("Helpers.zig");

const Allocator = std.mem.Allocator;
const Frame = Frame_Handler;
const Eth_Frame = Frame.Eth_Frame;
const Switch = Switch_Handler.Switch;
const print = std.debug.print;

// const IpAddress = ?[4]u8;

const EtherType = enum(u16) {
    IPv4 = 0x0800,
    ARP = 0x0806,
};

pub const Interface = struct {
    const Self = @This();

    name: []const u8,
    access_link: ?std.posix.socket_t,
    access_link_id: ?std.posix.sockaddr,
    MAC: MAC.MAC_Address,
    NAT_Table: NAT.NAT_Table, // table to keep track of open file descriptors and their bindings (IP:Port)
    gateway: [4]u8,

    pub fn init(allocator: Allocator, name: []const u8) !Interface {
        const NAT_Table = NAT.NAT_Table{ .values = NAT.NAT_List.init(allocator) };

        return Interface{
            .name = name,
            .access_link = undefined,
            .access_link_id = undefined,
            .MAC = Self.generate_mac_address(),
            .NAT_Table = NAT_Table,
            .gateway = [_]u8{0x00} ** 4,
        };
    }

    pub fn deinit(self: Self) void {
        self.NAT_Table.values.deinit();
    }

    pub fn send_frame(allocator: std.mem.Allocator, _switch: *Switch, frame: *Eth_Frame) !void {
        const buffer_len = Frame_Handler.Eth_Data_Size_Range[0] + 4;
        const buffer = try allocator.create([buffer_len]u8);
        defer allocator.destroy(buffer);

        buffer.* = .{0x12} ** buffer_len;

        var full_frame = [_]u8{0x00} ** (buffer_len + Frame_Handler.Eth_Header_Size);

        var offset: usize = 0;

        @memcpy(full_frame[offset .. offset + frame.dest.len], frame.dest[0..]);
        offset += frame.dest.len;

        @memcpy(full_frame[offset .. offset + frame.source.len], frame.source[0..]);
        offset += frame.source.len;

        @memcpy(full_frame[offset .. offset + frame.packet_type.len], frame.packet_type[0..]);
        offset += frame.packet_type.len;

        @memcpy(full_frame[offset..], buffer);

        _ = try _switch.send(_switch.socket.?, &full_frame, buffer_len);
    }

    pub fn stress_test(allocator: std.mem.Allocator, packet_switcher: *Switch, num_packets: usize) !void {
        var frame = Frame{
            .dest = .{ 0x10, 0x10, 0x10, 0x10, 0x10, 0x10 },
            .source = .{ 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
            .packet_type = .{ 0x08, 0x00 },
            .data = undefined,
        };

        std.debug.print("Sending {} Packets...", .{num_packets});

        const start_time = std.time.milliTimestamp();

        for (0..num_packets) |_| {
            try send_frame(allocator, packet_switcher, @constCast(&frame));
        }

        const end_time = std.time.milliTimestamp();
        const duration: u64 = @intCast(end_time - start_time);

        std.debug.print("\n=================================================\n", .{});
        std.debug.print(
            \\Details
            \\Total Packets Sent: {}
            \\Total Bytes Sent: {}
            \\Time: {d:.2}
            \\Packets / Second: {d:.2}
            \\Bytes / Second : {d:.2}
        , .{
            num_packets,
            std.fmt.fmtIntSizeDec(64 * num_packets),
            std.fmt.fmtDuration(duration * 1_000_000),
            (num_packets * 1000 / duration),
            std.fmt.fmtIntSizeDec((64 * num_packets * 1000 / duration)),
        });
        std.debug.print("\n", .{});
    }

    // Parse Frame here
    // Get IP & Port or other info if not IP protocol
    // forward traffic to corresponding binding (IP:Port) or proto
    pub fn forward_to_binding(self: *Interface, frame: Eth_Frame) void {
        _ = self;
        _ = frame;
    }

    fn generate_mac_address() MAC.MAC_Address {
        const timestamp: u64 = @intCast(std.time.nanoTimestamp() & 0xFFFFFFFFFFFFFFFF);
        var rnd = std.Random.DefaultPrng.init(timestamp);
        const generated_address: u48 = @intCast(rnd.next() & 0xFFFF);

        const new_mac = MAC.MAC_Address{
            .address = generated_address,
        };

        return new_mac;
    }

    pub fn log(self: Self) void {
        print("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++ vInterface {s} +++++++++++++++++++++++++++++++++++++++++++++++++++++++\n", .{self.name});
        print("Name: {s}\n", .{self.name});
        Helpers.print_mac_address(self.MAC);
        print("Bridge: {?}\n", .{self.access_link_id});
        print("Gateway: {any}\n", .{self.gateway});
        Helpers.print_NAT_Table(self.NAT_Table.values);
        print("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n", .{});
    }
};

test "interface_generate_mac_address" {}

test "interface_send_frame" {}

test "interface_forward_to_binding" {}
