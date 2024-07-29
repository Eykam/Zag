const std = @import("std");
const Frame = @import("Frame.zig");
const Helpers = @import("Helpers.zig");
const MAC_Address_Table = @import("./MAC_Table.zig").MAC_Address_Table;
const Packets = @import("L3").Packets;

const fs = std.fs;
const Eth_Frame = Frame.Eth_Frame;
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

// Simulating a port on a switch. Each port will have a read / write pipe with an associated MAC_Address
// for forwarding Eth_Packets
pub const Port = struct {
    id: usize,
    MAC_Address_Table: MAC_Address_Table, //mapping of MAC_Address to pipes
    socket: ?std.posix.socket_t, //for forwarding to physical network if device not found
    socket_address: std.posix.sockaddr.ll,

    fn init(self: *Switch, interface: []const u8) !void {
        // Create a raw socket
        const socket = try std.posix.socket(AF_PACKET, SOCK_TYPE, std.mem.nativeToBig(
            u32,
            PACKET_PROTO,
        ));

        if (socket < 0) {
            std.debug.print("Error creating socket\n", .{});
            return;
        }

        std.debug.print("Raw socket created successfully!\n", .{});
        const mac_addr = try Helpers.getMacAddress(interface);

        // Todo: find way to get these values programmatically / at comptime
        self.socket_address = std.posix.sockaddr.ll{
            .family = AF_PACKET,
            .protocol = std.mem.nativeToBig(u16, PACKET_PROTO),
            .ifindex = IF_INDEX,
            .hatype = 1,
            .pkttype = 0,
            .halen = 6,
            .addr = mac_addr,
        };

        self.socket = socket;
        try self.log();
        return;
    }

    fn bind_to_socket(self: *Switch) !void {
        const addr_ptr = @as(*const std.posix.sockaddr, @ptrCast(&self.address));
        try std.posix.bind(self.socket.?, addr_ptr, @sizeOf(std.posix.sockaddr.ll));
    }

    fn recvfrom(self: *Switch, buffer: []u8) !void {
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
    fn open(self: *Switch) !void {
        var buffer: [Frame.Eth_Total_Frame_Size_Range[1]]u8 = undefined;

        while (true) {
            try self.recvfrom(&buffer);
        }
    }

    fn log(self: *Switch) !void {
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
    fn exit_log(self: *Switch) !void {
        _ = self;
    }

    fn forward_to_physical_interface(self: *Switch, sockfd: std.posix.socket_t, frame: []const u8, data_len: u8) !bool {
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

pub const Switch = struct {
    const Self = @This();

    eth_port_mapping: std.hash_map, // map of associated mac_address with read/write pipe for communication between interface and switch threads
    allocator: Allocator,

    pub fn init(allocator: Allocator) !void {
        return Self{
            .eth_port_mapping = undefined,
            .allocator = allocator,
        };
    }

    pub fn deinit() !void {}
};

test "raw_socket_operations" {}
