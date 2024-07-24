const std = @import("std");
const L2Sockets = @import("./layer2_datalink/Sockets.zig");
const L2Packets = @import("./layer2_datalink/Packets.zig");
const Raw_Socket = L2Sockets.Raw_Socket;

const MAX_FRAME_SIZE = L2Packets.Eth_Total_Frame_Size_Range[1];
const INTERFACE = "eth0";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var socket = try allocator.create(Raw_Socket);
    defer allocator.destroy(socket);

    try socket.init(INTERFACE);
    try socket.bind();

    var buffer: [MAX_FRAME_SIZE]u8 = undefined;

    while (true) {
        try socket.recvfrom(&buffer);
        // try socket2.recvfrom(&buffer2);
    }
}

test "network stack & pipeline test" {
    // cases:
    // - Multiple sockets initialized
    // - memory management
}
