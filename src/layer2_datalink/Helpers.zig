const std = @import("std");
const fs = std.fs;
const mem = std.mem;

pub fn getMacAddress(interface: []const u8) !([8]u8) {
    var path_buffer: [64]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buffer, "/sys/class/net/{s}/address", .{interface});

    const file = try fs.openFileAbsolute(path, .{});
    defer file.close();

    var buf: [18]u8 = undefined; // MAC address is 17 chars + newline
    const bytes_read = try file.readAll(&buf);
    if (bytes_read < 17) return error.InvalidMacAddress;

    var mac: [8]u8 = [_]u8{0} ** 8;
    var mac_parts = mem.splitSequence(u8, buf[0..17], ":");
    var i: usize = 0;
    while (mac_parts.next()) |part| : (i += 1) {
        if (i >= 8) return error.InvalidMacAddress;
        mac[i] = try std.fmt.parseInt(u8, part, 16);
    }

    return mac;
}

// const SharedParams = struct {
//     allocator: std.mem.Allocator,
//     num_packets: usize,
// };

// const ThreadResult = struct {
//     duration: u64,
//     packets_sent: usize,
// };

// fn stress_test_runner(params: *const SharedParams, result: *ThreadResult) !void {
//     const allocator = params.allocator;
//     const num_packets = params.num_packets;

//     const socket: *Switch = try allocator.create(Switch);
//     defer allocator.destroy(socket);

//     try socket.init(INTERFACE);
//     try socket.bind();

//     var frame = L2Packets.Eth_Frame{
//         .dest = .{ 0x10, 0x10, 0x10, 0x10, 0x10, 0x10 },
//         .source = .{ 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
//         .packet_type = .{ 0x08, 0x00 },
//         .data = undefined,
//     };

//     const start_time = std.time.milliTimestamp();

//     for (0..num_packets) |_| {
//         try send_frame(allocator, socket, @constCast(&frame));
//     }

//     const end_time = std.time.milliTimestamp();
//     const duration: u64 = @intCast(end_time - start_time);

//     result.duration = duration;
//     result.packets_sent = num_packets;
// }

// pub fn send_stress_test(allocator: std.mem.Allocator, num_packets: usize) !void {
//     const num_cores = try std.Thread.getCpuCount();
//     std.debug.print("Number of CPU cores: {}\n", .{num_cores});

//     var threads = try allocator.alloc(std.Thread, num_cores);
//     defer allocator.free(threads);
//     var results = try allocator.alloc(ThreadResult, num_cores);
//     defer allocator.free(results);

//     const params = SharedParams{
//         .allocator = allocator,
//         .num_packets = num_packets / num_cores,
//     };

//     // Create and bind threads to specific cores
//     for (0..num_cores) |i| {
//         const thread = try std.Thread.spawn(.{}, stress_test_runner, .{ &params, &results[i] });
//         threads[i] = thread;

//         // Set CPU affinity for the thread (Linux-specific)
//         var cpu_set = std.os.linux.cpu_set_t{};
//         std.posix.CPU_ZERO(&cpu_set);
//         std.os.CPU_SET(i, &cpu_set);

//         const pid = std.os.linux.gettid();
//         const rc = std.os.linux.syscall3(.sched_setaffinity, pid, @sizeOf(std.os.cpu_set_t), @intFromPtr(&cpu_set));
//         // if (std.os.getErrno(rc) != .SUCCESS) {
//         std.debug.print("Setting CPU affinity for thread {}: {}\n", .{ i, rc });
//         // }
//     }

//     // Join threads and aggregate results
//     var total_duration: u64 = 0;
//     var total_packets_sent: usize = 0;
//     for (threads, 0..) |*thread, i| {
//         thread.join();
//         total_duration += results[i].duration;
//         total_packets_sent += results[i].packets_sent;
//     }

//     const avg_duration = total_duration / num_cores;
//     const total_bytes_sent = total_packets_sent * 64; // Assuming 64 bytes per packet

//     std.debug.print("\n=================================================\n", .{});
//     std.debug.print(
//         \\Details
//         \\Total Packets Sent: {}
//         \\Total Bytes Sent: {}
//         \\Time: {d:.2} ms
//         \\Packets / Second: {d:.2}
//         \\Bytes / Second : {d:.2}
//     , .{
//         total_packets_sent,
//         std.fmt.fmtIntSizeDec(total_bytes_sent),
//         @as(f64, @floatFromInt(avg_duration)),
//         @as(f64, @floatFromInt(total_packets_sent * 1000)) / @as(f64, @floatFromInt(avg_duration)),
//         std.fmt.fmtIntSizeDec((total_bytes_sent * 1000) / avg_duration),
//     });
//     std.debug.print("\n", .{});

//     std.debug.print("All threads have completed\n", .{});
// }

test "get_mac_addr" {}
