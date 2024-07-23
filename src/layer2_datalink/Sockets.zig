const std = @import("std");
const Packets = @import("Packets.zig");
const Eth_Parser = Packets.Eth_Parser;
const Eth_Packet = Packets.Eth_Packet;

const PACKET_PROTO: u32 = 0x0003; // cat /etc/protocols => IP protocol
const AF_PACKET: u32 = @as(u32, std.posix.AF.PACKET); // TODO: maybe consider getting LLC too ??
const SOCK_TYPE: u32 = @as(u32, std.posix.SOCK.RAW);
const IF_INDEX: i32 = 2;

// Make sure memory aligned??
// Might not need to be optimized since not many sockets open at once
const Raw_Socket = struct {
    socket: ?std.posix.socket_t,
    address: std.posix.sockaddr.ll,
    pub fn init(self: *Raw_Socket) !void {
        // Create a raw socket
        const socket = try std.posix.socket(AF_PACKET, SOCK_TYPE, std.mem.nativeToBig(
            u32,
            PACKET_PROTO,
        ));

        if (socket < 0) {
            std.debug.print("Error creating socket\n", .{});
            return;
        }

        // Todo: find way to get these values programmatically / at comptime
        self.address = std.posix.sockaddr.ll{
            .family = AF_PACKET,
            .protocol = std.mem.nativeToBig(u16, PACKET_PROTO),
            .ifindex = IF_INDEX,
            .hatype = 1,
            .pkttype = 0,
            .halen = 6,
            .addr = [8]u8{ 0x00, 0x15, 0x5d, 0xa4, 0x34, 0xb0, 0, 0 },
        };

        std.debug.print("Raw socket created successfully! {}\n", .{socket});
        self.socket = socket;
        return;
    }

    pub fn bind(self: *Raw_Socket) !void {
        const addr_ptr = @as(*const std.posix.sockaddr, @ptrCast(&self.address));
        try std.posix.bind(self.socket.?, addr_ptr, @sizeOf(std.posix.sockaddr.ll));
    }

    pub fn recvfrom(self: *Raw_Socket, buffer: []u8) !void {
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

        var curr_packet = try Eth_Parser.parse(allocator, buffer);
        defer curr_packet.deinit(allocator);

        // get list of types from libc. Switch statement over
        // types w/ L3 packet parser to process each.
        const packet_typ_u16 = @as(u16, curr_packet.packet_type[0]) << 8 | curr_packet.packet_type[1];
        switch (packet_typ_u16) {
            0x0800 => {
                std.debug.print("==== Found IPV4! ====\n", .{});
            },
            else => {},
            // 0x0,
        }
    }

    pub fn sendTo() !void {} // TODO: Implement
    pub fn close() !void {} // TODO: Implement
};

// need to remove this from here => main.zig.
// Find way to return self, to make chainable pipe
// ex: socket.init().bind().recvfrom()...etc;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var socket = try allocator.create(Raw_Socket);
    defer allocator.destroy(socket);

    try socket.init();
    try socket.bind();

    std.debug.print("Raw socket listening on interface ...\n", .{});

    var buffer: [1522]u8 = undefined;
    while (true) {
        try socket.recvfrom(&buffer);
    }
}

test "raw_socket_test" {
    // std.debug.print("Testing raw socket!", .{});
    // var socket = Raw_Socket{};
    // defer socket.close(socket);
    // try socket.init();
    // try socket.bind();
    // try socket.recv();
}
