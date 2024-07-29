const std = @import("std");
const L2 = @import("L2");

const Switch = L2.Switch_Handler.Switch;
const Frame_Handler = L2.Frame_Handler;
const Frame = Frame_Handler.Eth_Frame;

const MAX_FRAME_SIZE = Frame_Handler.Eth_Total_Frame_Size_Range[1];
const INTERFACE = "eth0";

// ================================================================================
// For testing / dev
// Todo: move to appropriate location

fn send_frame(allocator: std.mem.Allocator, packet_switcher: *Switch, frame: *Frame) !void {
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

    _ = try packet_switcher.send(packet_switcher.socket.?, &full_frame, buffer_len);
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

// ================================================================================

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const packet_switcher = try allocator.create(Switch);
    defer allocator.destroy(packet_switcher);

    try packet_switcher.init(INTERFACE);
    try packet_switcher.bind();

    const num_packets = 1_000_000;
    try stress_test(allocator, packet_switcher, num_packets);

    // try open(packet_switcher);
}

test "network stack & pipeline test" {
    // cases:
    // - Multiple sockets initialized
    // - memory management
    // - sending sockets
    // - max bitrate vs std lib / existing solutions
}
