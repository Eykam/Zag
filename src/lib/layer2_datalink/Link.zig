const std = @import("std");
const Frame = @import("Frame.zig");
const Helpers = @import("../utils/Helpers.zig");
const Interface_Handler = @import("Interface.zig");
const MAC = @import("./MAC.zig");
const MAC_Address_Table = MAC.MAC_Address_Table;
const Packets = @import("../layer3_network/Packets.zig");

const fs = std.fs;
const Eth_Frame = Frame.Eth_Frame;
const Interface = Interface_Handler.Interface;
const Allocator = std.mem.Allocator;

const PACKET_PROTO: u32 = 0x0003; // cat /etc/protocols => IP protocol
const IF_INDEX: i32 = 2;

const AF_PACKET: u32 = @as(u32, std.posix.AF.PACKET);
const SOCK_TYPE: u32 = @as(u32, std.posix.SOCK.RAW);

const Packet_Type = enum(u16) {
    IPv4 = 0x0800,
    IPV6 = 0x86dd,
    ARP = 0x0806,
    LLDP = 0x88cc,
};

// Simulating a Link on a switch.
// Each Link will represent packet transfer using read / write pipe between an interface and a switch
pub const Link = struct {
    const Self = @This();
    const QueueSize = 1024;

    allocator: Allocator,
    to_switch: []u8, // placeholder for now, until event loop is implemented
    to_interface: []u8, // placeholder for now, until event loop is implemented
    packetQueue: std.RingBuffer,

    pub fn init(allocator: Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .allocator = allocator,
            .to_switch = .{},
            .to_interface = .{},
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        while (self.to_switch.get()) |node| {
            self.allocator.free(node.data.data);
            self.allocator.destroy(node);
        }
        while (self.to_interface.get()) |node| {
            self.allocator.free(node.data.data);
            self.allocator.destroy(node);
        }
        self.allocator.destroy(self);
    }

    pub fn hash(self: Self) u64 {
        return std.hash.Wyhash.hash(0, &self.interface_0 + &self.interface_1);
    }

    pub fn eql(self: Self, other: Self) bool {
        return std.mem.eql(u8, &self.address, &other.address);
    }

    fn recvfrom(self: *Self, buffer: []u8) !void {
        var src_addr: std.posix.sockaddr.ll = undefined;
        var addr_len: std.posix.socklen_t = @sizeOf(std.posix.sockaddr.ll);
        const src_addr_ptr = @as(*std.posix.sockaddr, @ptrCast(&src_addr));

        _ = try std.posix.recvfrom(
            self.socket.?,
            buffer,
            0,
            src_addr_ptr,
            &addr_len,
        );

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        var curr_frame = try Eth_Frame.parse(allocator, buffer);
        defer curr_frame.destroy(allocator);

        // get list of types from libc. Switch statement over
        // types w/ L3 packet parser to process each.
        // Get IP and Port if IP proto, forward to corresponding mapping
        const packet_typ_u16 = @as(u16, curr_frame.packet_type[0]) << 8 | curr_frame.packet_type[1];
        switch (packet_typ_u16) {
            @intFromEnum(Packet_Type.IPv4) => {
                std.debug.print("==== Found IPV4 Packet! ====\n", .{});
                // Packets.IPv4_Packet.unpack(curr_frame);
            },
            @intFromEnum(Packet_Type.IPV6) => {
                std.debug.print("==== Found IPV6 Packet! ====\n", .{});
                // Packets.IPv6_Packet.unpack(curr_frame);
            },
            @intFromEnum(Packet_Type.ARP) => {
                std.debug.print("==== Found ARP Packet! ====\n", .{});
                // Packets.ARP_Packet.unpack(curr_frame);
            },
            @intFromEnum(Packet_Type.LLDP) => {
                std.debug.print("==== Found LLDP Packet! ====\n", .{});
                // Packets.LLDP_Packet.unpack(curr_frame);
            },
            else => {
                std.debug.print("==== Found UNKNOWN Packet: {x:0>4}! ====\n", .{packet_typ_u16});
            },
        }
    }

    // Find way to open this in another thread?
    fn open(self: *Self) !void {
        var buffer: [Frame.Eth_Total_Frame_Size_Range[1]]u8 = undefined;

        while (true) {
            try self.recvfrom(&buffer);
        }
    }

    fn log(self: *Self) !void {
        std.debug.print("Socket ID:{?}\nInterface: ", .{self.socket});
        inline for (self.socket_address.addr, 0..) |byte, ind| {
            const last = if (ind < self.socket_address.addr.len - 1) ":" else "";
            std.debug.print("{x:0>2}{s}", .{
                byte,
                last,
            });
        }
        std.debug.print("\n", .{});
    }

    // Print stats of dropped packets / avg processing time,
    // total packets & data sent, etc. when switch is closed
    fn exit_log(self: *Self) !void {
        _ = self;
    }

    fn forward_to_physical_interface(self: *Self, sockfd: std.posix.socket_t, frame: []const u8, data_len: u8) !bool {
        _ = self;

        const flags: u32 = 0;

        var total_sent: usize = 0;
        const total_size = Frame.Eth_Header_Size + data_len;

        while (total_sent < total_size) {
            const bytes_sent = std.posix.send(sockfd, frame[total_sent..], flags) catch |err| {
                std.debug.print("Error sending frames from L2 Switch!\n {}", .{err});
                return false;
            };
            total_sent += bytes_sent;
        }
        return true;
    }

    fn forward_to_virtual_interface() void {} // TODO: Implement

    fn close() !void {} // TODO: Implement

};

const testing = std.testing;

test "read_write" {}
