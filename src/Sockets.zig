const std = @import("std");
const Packets = @import("Packets.zig");

// cat /etc/protocols => IP protocol
const Eth_Packet = Packets.Eth_Packet;
const PACKET_PROTO: u32 = 0x0003;
const AF_PACKET: u32 = @as(u32, std.posix.AF.PACKET);
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

        // find way to get these values programmatically / at comptime
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

        const bytes_received = try std.posix.recvfrom(
            self.socket.?,
            buffer,
            0,
            src_addr_ptr,
            &addr_len,
        );

        var curr_packet = Eth_Packet{
            .dest = undefined,
            .source = undefined,
            .type = undefined,
            .data = undefined,
        };

        try curr_packet.init(buffer, @as(u16, @min(bytes_received, 0xFFFF)));

        std.debug.print("===============================\n", .{});
        std.debug.print("Received {} bytes\n", .{bytes_received});

        // Print the first 20 bytes of the packet (adjust as needed)
        // for (buffer[0..@min(12, bytes_received)]) |byte| {
        //     std.debug.print("{x:0>2} ", .{byte});
        // }

        std.debug.print("Dest MAC: {x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}\n", .{
            curr_packet.dest[0],
            curr_packet.dest[1],
            curr_packet.dest[2],
            curr_packet.dest[3],
            curr_packet.dest[4],
            curr_packet.dest[5],
        });
        std.debug.print("Source MAC: {x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}:{x:0>2}\n", .{
            curr_packet.source[0],
            curr_packet.source[1],
            curr_packet.source[2],
            curr_packet.source[3],
            curr_packet.source[4],
            curr_packet.source[5],
        });
        std.debug.print("Type: {x:0>2}\n", .{curr_packet.type});
    }

    pub fn close() !void {}
};

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

// test "UDP_test" {
//     std.debug.print("Testing UDP!", .{});
//     var socket = Socket{};
//     //   defer socket.close(socket);
//     try socket.init();
//     // try socket.bind();
//     try socket.recv();
// }
