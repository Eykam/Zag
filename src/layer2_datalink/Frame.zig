const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

pub const Eth_Header_Size = 14;
pub const Eth_Data_Size_Range = .{ 46, 1500 };
pub const Eth_Total_Frame_Size_Range = .{ Eth_Data_Size_Range[0] + Eth_Header_Size, Eth_Data_Size_Range[1] + Eth_Header_Size };

pub const Eth_Frame = struct {
    const Self = @This();

    dest: [6]u8,
    source: [6]u8,
    packet_type: [2]u8,
    data: []u8,
    pub fn destroy(self: *Eth_Frame, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn parse(allocator: std.mem.Allocator, raw_frame: []const u8) !Eth_Frame {
        if (raw_frame.len < Eth_Header_Size) {
            return error.frameTooSmall;
        }

        var frame = Eth_Frame{
            .dest = undefined,
            .source = undefined,
            .packet_type = undefined,
            .data = undefined,
        };

        @memcpy(&frame.dest, raw_frame[0..6]);
        @memcpy(&frame.source, raw_frame[6..12]);
        @memcpy(&frame.packet_type, raw_frame[12..14]);

        const data_start_index = frame.dest.len + frame.source.len + frame.packet_type.len;
        const data_len = raw_frame.len - data_start_index;

        if (data_len < Eth_Data_Size_Range[0]) {
            frame.data = try allocator.alloc(u8, Eth_Data_Size_Range[0]);
            @memcpy(frame.data[0..data_len], raw_frame[data_start_index..]);
            @memset(frame.data[data_len..], 0x00);
        } else {
            const copy_len = @min(Eth_Data_Size_Range[1], data_len);
            frame.data = try allocator.alloc(u8, copy_len);
            @memcpy(frame.data[0..copy_len], raw_frame[data_start_index..(data_start_index + copy_len)]);
        }

        frame.log();
        return frame;
    }

    pub fn log(self: *Eth_Frame) void {
        print("\n================ Ethernet Frame =================\n", .{});

        print("Total Frame Size: {} Bytes\n", .{@sizeOf(@TypeOf(self.*))});

        // Dest
        print("Dest MAC: ", .{});
        inline for (self.dest, 0..) |byte, ind| {
            const last = if (ind < self.dest.len - 1) ":" else "";
            print("{x:0>2}{s}", .{
                byte,
                last,
            });
        }
        print("\n", .{});

        // Source
        print("Source MAC: ", .{});
        inline for (self.source, 0..) |byte, ind| {
            const last = if (ind < self.source.len - 1) ":" else "";
            print("{x:0>2}{s}", .{
                byte,
                last,
            });
        }
        print("\n", .{});

        // Type
        print("Type: 0x", .{});
        inline for (self.packet_type) |byte| {
            print("{x:0>2}", .{byte});
        }

        print("\n", .{});
        print("Data Size: {} Bytes\n", .{self.data.len});
        print("\n", .{});

        // Data
        for (0..self.data.len) |ind| {
            if (ind != 0 and (ind % 16) == 0) {
                print("\n", .{});
            } else if (ind != 0 and (ind % 8) == 0) {
                print("  ", .{});
            }
            print("{x:0>2} ", .{self.data[ind]});
        }
        print("\n", .{});
    }
    pub fn obfuscate() !void {
        // take bytes in and do random bitshift. No other purpose than to
        // hide my IP / MAC address when posting snippets on twitter.
    }
    pub fn to_slice() ![]const u8 {}
};

// ==============================================================================================================

const testing = std.testing;

test "eth_frame_parsing_minimum_size" {
    const allocator = testing.allocator;

    const min_frame = [_]u8{0} ** Eth_Total_Frame_Size_Range[0];
    var frame = try Eth_Frame.parse(allocator, &min_frame);
    defer frame.destroy(allocator);

    try testing.expectEqual(@as(usize, 6), frame.dest.len);
    try testing.expectEqual(@as(usize, 6), frame.source.len);
    try testing.expectEqual(@as(usize, 2), frame.packet_type.len);
    try testing.expectEqual(@as(usize, Eth_Data_Size_Range[0]), frame.data.len);
}

test "eth_frame_parsing_undersized_frame_invalid_header" {
    const allocator = testing.allocator;
    const small_frame = [_]u8{0} ** (Eth_Header_Size - 1);
    const frame = Eth_Frame.parse(allocator, &small_frame);
    const expected_error = error.frameTooSmall;
    try testing.expectError(expected_error, frame);
}

// Expect to pass, as long as > 14
test "eth_frame_parsing_undersized_frame_valid_header" {
    const allocator = testing.allocator;

    const small_frame = [_]u8{0} ** (Eth_Header_Size);
    var frame = try Eth_Frame.parse(allocator, &small_frame);
    defer frame.destroy(allocator);

    try testing.expectEqual(@as(usize, 6), frame.dest.len);
    try testing.expectEqual(@as(usize, 6), frame.source.len);
    try testing.expectEqual(@as(usize, 2), frame.packet_type.len);
    try testing.expectEqual(@as(usize, Eth_Data_Size_Range[0]), frame.data.len);
}

test "eth_frame_parsing_maximum_size" {
    const allocator = testing.allocator;

    const max_frame = [_]u8{0} ** Eth_Total_Frame_Size_Range[1];
    var frame = try Eth_Frame.parse(allocator, &max_frame);
    defer frame.destroy(allocator);

    try testing.expectEqual(@as(usize, 6), frame.dest.len);
    try testing.expectEqual(@as(usize, 6), frame.source.len);
    try testing.expectEqual(@as(usize, 2), frame.packet_type.len);
    try testing.expectEqual(@as(usize, Eth_Data_Size_Range[1]), frame.data.len);
}

test "eth_frame_parsing_oversized_frame" {
    const allocator = testing.allocator;

    const large_frame = [_]u8{0} ** (Eth_Total_Frame_Size_Range[1] + 50);
    var frame = try Eth_Frame.parse(allocator, &large_frame);
    defer frame.destroy(allocator);

    try testing.expectEqual(@as(usize, 6), frame.dest.len);
    try testing.expectEqual(@as(usize, 6), frame.source.len);
    try testing.expectEqual(@as(usize, 2), frame.packet_type.len);
    try testing.expectEqual(@as(usize, Eth_Data_Size_Range[1]), frame.data.len);
}

test "eth_frame_parsing_valid_frame_with_specific_values" {
    const allocator = testing.allocator;

    const valid_frame = [_]u8{
        0x00, 0x11, 0x22, 0x33, 0x44, 0x55, // Destination MAC
        0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, // Source MAC
        0x08, 0x00, // EtherType (IPv4)
        0x45, 0x00, 0x00, 0x28, // Start of IP header
        0, 0, 0, 0, 0, 0, 0, 0, // Remaining 46 bytes to meet minimum frame size
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
    };
    var frame = try Eth_Frame.parse(allocator, &valid_frame);
    defer frame.destroy(allocator);

    try testing.expectEqualSlices(u8, &[_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 }, &frame.dest);
    try testing.expectEqualSlices(u8, &[_]u8{ 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF }, &frame.source);
    try testing.expectEqualSlices(u8, &[_]u8{ 0x08, 0x00 }, &frame.packet_type);
    try testing.expect(frame.data.len >= Eth_Data_Size_Range[0] and frame.data.len <= Eth_Data_Size_Range[1]);
    try testing.expectEqual(@as(u8, 0x45), frame.data[0]);
}

test "eth_frame_parsing_valid_frame_with_specific_values_larger" {
    const allocator = testing.allocator;

    const valid_frame = [_]u8{
        0x00, 0x11, 0x22, 0x33, 0x44, 0x55, // Destination MAC
        0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, // Source MAC
        0x08, 0x00, // EtherType (IPv4)
        0x45, 0x00, 0x00, 0x28, // Start of IP header
    };

    // Make frame max size + 1, then set test bit at position 1500 to 0x99 to test
    const current_frame_len = valid_frame.len - Eth_Header_Size;
    const extended_data_len = Eth_Data_Size_Range[1] - current_frame_len - 1;

    const extended_frame: [extended_data_len + 2]u8 = [_]u8{0} ** (extended_data_len) ++ [_]u8{ 0x99, 0x01 };
    const full_frame = valid_frame ++ extended_frame;

    var frame = try Eth_Frame.parse(allocator, &full_frame);
    defer frame.destroy(allocator);

    try testing.expectEqualSlices(u8, &[_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 }, &frame.dest);
    try testing.expectEqualSlices(u8, &[_]u8{ 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF }, &frame.source);
    try testing.expectEqualSlices(u8, &[_]u8{ 0x08, 0x00 }, &frame.packet_type);
    try testing.expect(frame.data.len >= Eth_Data_Size_Range[0] and frame.data.len <= Eth_Data_Size_Range[1]);
    try testing.expectEqual(@as(u8, 0x99), frame.data[frame.data.len - 1]);
}

test "eth_frame_parsing_valid_frame_with_specific_values_unpadded" {
    const allocator = testing.allocator;

    const valid_frame = [_]u8{
        0x00, 0x11, 0x22, 0x33, 0x44, 0x55, // Destination MAC
        0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, // Source MAC
        0x08, 0x00, // EtherType (IPv4)
        0x45, 0x00, 0x00, 0x28, // Start of IP header
        // Missing 46 bytes to meet minimum frame size
    };

    var frame = try Eth_Frame.parse(allocator, &valid_frame);
    defer frame.destroy(allocator);

    try testing.expectEqualSlices(u8, &[_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 }, &frame.dest);
    try testing.expectEqualSlices(u8, &[_]u8{ 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF }, &frame.source);
    try testing.expectEqualSlices(u8, &[_]u8{ 0x08, 0x00 }, &frame.packet_type);
    try testing.expectEqual(@as(usize, Eth_Data_Size_Range[0]), frame.data.len);
    try testing.expectEqual(@as(u8, 0x45), frame.data[0]);
}
