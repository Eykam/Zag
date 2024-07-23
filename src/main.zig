const std = @import("std");
const L2Sockets = @import("./layer2_datalink/Sockets.zig");
const L2Packets = @import("./layer2_datalink/Packets.zig");
const Raw_Socket = L2Sockets.Raw_Socket;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var socket = try allocator.create(Raw_Socket);
    defer allocator.destroy(socket);

    const interface = "eth0";
    try socket.init(interface);
    try socket.bind();

    const max_packet_size = L2Packets.EthPacketSizeRange[1];
    var buffer: [max_packet_size]u8 = undefined;
    while (true) {
        try socket.recvfrom(&buffer);
    }
}

test "network stack & pipeline test" {}
