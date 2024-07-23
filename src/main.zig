const std = @import("std");
const L2Sockets = @import("./layer2_datalink/Sockets.zig");
const L2Packets = @import("./layer2_datalink/Packets.zig");
const Raw_Socket = L2Sockets.Raw_Socket;

const MAX_PACKET_SIZE = L2Packets.EthPacketSizeRange[1];
const INTERFACE = "eth0";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var socket = try allocator.create(Raw_Socket);
    defer allocator.destroy(socket);

    try socket.init(INTERFACE);
    try socket.bind();

    var buffer: [MAX_PACKET_SIZE]u8 = undefined;

    // test to see whether creating 2 sockets causes isuses

    // var socket2 = try allocator.create(Raw_Socket);
    // defer allocator.destroy(socket2);

    // try socket2.init(INTERFACE);
    // try socket2.bind();

    // var buffer2: [MAX_PACKET_SIZE]u8 = undefined;

    while (true) {
        try socket.recvfrom(&buffer);
        // try socket2.recvfrom(&buffer2);
    }
}

test "network stack & pipeline test" {}
