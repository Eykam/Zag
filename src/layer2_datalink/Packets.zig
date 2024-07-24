const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

pub const Eth_Header_Size = 14;
pub const Eth_Data_Size_Range = .{ 46, 1500 };
pub const Eth_Total_Frame_Size_Range = .{ Eth_Data_Size_Range[0] + Eth_Header_Size, Eth_Data_Size_Range[1] + Eth_Header_Size };

pub const Eth_Packet = struct {
    dest: [6]u8,
    source: [6]u8,
    packet_type: [2]u8,
    data: []u8,
    pub fn deinit(self: *Eth_Packet, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn log(self: *Eth_Packet, data_len: usize) void {
        print("\n================ Ethernet Frame =================\n", .{});

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
        print("Data Size: {} Bytes\n", .{data_len});
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
};

// TODO: Figure out what to do in the case that ethernet packet is less than 64 bytes
//       Double check to make sure that 64 bytes is the correct min length of eth frame
pub const Eth_Parser = struct {
    pub fn parse(allocator: std.mem.Allocator, raw_frame: []const u8) !Eth_Packet {
        if (raw_frame.len < Eth_Header_Size) {
            return error.PacketTooSmall;
        }

        var packet = Eth_Packet{
            .dest = undefined,
            .source = undefined,
            .packet_type = undefined,
            .data = undefined,
        };

        @memcpy(&packet.dest, raw_frame[0..6]);
        @memcpy(&packet.source, raw_frame[6..12]);
        @memcpy(&packet.packet_type, raw_frame[12..14]);

        const data_start_index = packet.dest.len + packet.source.len + packet.packet_type.len;
        const data_len = raw_frame.len - data_start_index;

        if (data_len < Eth_Data_Size_Range[0]) {
            packet.data = try allocator.alloc(u8, Eth_Data_Size_Range[0]);
            @memcpy(packet.data[0..data_len], raw_frame[data_start_index..]);
            @memset(packet.data[data_len..], 0x00);
        } else {
            const copy_len = @min(Eth_Data_Size_Range[1], data_len);
            packet.data = try allocator.alloc(u8, copy_len);
            @memcpy(packet.data[0..copy_len], raw_frame[data_start_index..(data_start_index + copy_len)]);
        }

        packet.log(data_len);
        return packet;
    }
};

const testing = std.testing;

test "eth_packet_parsing_minimum_size" {
    const allocator = testing.allocator;

    const min_frame = [_]u8{0} ** Eth_Total_Frame_Size_Range[0];
    var packet = try Eth_Parser.parse(allocator, &min_frame);
    defer packet.deinit(allocator);

    try testing.expectEqual(@as(usize, 6), packet.dest.len);
    try testing.expectEqual(@as(usize, 6), packet.source.len);
    try testing.expectEqual(@as(usize, 2), packet.packet_type.len);
    try testing.expectEqual(@as(usize, Eth_Data_Size_Range[0]), packet.data.len);
}

test "eth_packet_parsing_undersized_packet_invalid_header" {
    const allocator = testing.allocator;
    const small_frame = [_]u8{0} ** (Eth_Header_Size - 1);
    const packet = Eth_Parser.parse(allocator, &small_frame);
    const expected_error = error.PacketTooSmall;
    try testing.expectError(expected_error, packet);
}

// Expect to pass, as long as > 14
test "eth_packet_parsing_undersized_packet_valid_header" {
    const allocator = testing.allocator;

    const small_frame = [_]u8{0} ** (Eth_Header_Size);
    var packet = try Eth_Parser.parse(allocator, &small_frame);
    defer packet.deinit(allocator);

    try testing.expectEqual(@as(usize, 6), packet.dest.len);
    try testing.expectEqual(@as(usize, 6), packet.source.len);
    try testing.expectEqual(@as(usize, 2), packet.packet_type.len);
    try testing.expectEqual(@as(usize, Eth_Data_Size_Range[0]), packet.data.len);
}

test "eth_packet_parsing_maximum_size" {
    const allocator = testing.allocator;

    const max_frame = [_]u8{0} ** Eth_Total_Frame_Size_Range[1];
    var packet = try Eth_Parser.parse(allocator, &max_frame);
    defer packet.deinit(allocator);

    try testing.expectEqual(@as(usize, 6), packet.dest.len);
    try testing.expectEqual(@as(usize, 6), packet.source.len);
    try testing.expectEqual(@as(usize, 2), packet.packet_type.len);
    try testing.expectEqual(@as(usize, Eth_Data_Size_Range[1]), packet.data.len);
}

test "eth_packet_parsing_oversized_packet" {
    const allocator = testing.allocator;

    const large_frame = [_]u8{0} ** (Eth_Total_Frame_Size_Range[1] + 50);
    var packet = try Eth_Parser.parse(allocator, &large_frame);
    defer packet.deinit(allocator);

    try testing.expectEqual(@as(usize, 6), packet.dest.len);
    try testing.expectEqual(@as(usize, 6), packet.source.len);
    try testing.expectEqual(@as(usize, 2), packet.packet_type.len);
    try testing.expectEqual(@as(usize, Eth_Data_Size_Range[1]), packet.data.len);
}

test "eth_packet_parsing_valid_packet_with_specific_values" {
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
    var packet = try Eth_Parser.parse(allocator, &valid_frame);
    defer packet.deinit(allocator);

    try testing.expectEqualSlices(u8, &[_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 }, &packet.dest);
    try testing.expectEqualSlices(u8, &[_]u8{ 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF }, &packet.source);
    try testing.expectEqualSlices(u8, &[_]u8{ 0x08, 0x00 }, &packet.packet_type);
    try testing.expect(packet.data.len >= Eth_Data_Size_Range[0] and packet.data.len <= Eth_Data_Size_Range[1]);
    try testing.expectEqual(@as(u8, 0x45), packet.data[0]);
}

test "eth_packet_parsing_valid_packet_with_specific_values_larger" {
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

    var packet = try Eth_Parser.parse(allocator, &full_frame);
    defer packet.deinit(allocator);

    try testing.expectEqualSlices(u8, &[_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 }, &packet.dest);
    try testing.expectEqualSlices(u8, &[_]u8{ 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF }, &packet.source);
    try testing.expectEqualSlices(u8, &[_]u8{ 0x08, 0x00 }, &packet.packet_type);
    try testing.expect(packet.data.len >= Eth_Data_Size_Range[0] and packet.data.len <= Eth_Data_Size_Range[1]);
    try testing.expectEqual(@as(u8, 0x99), packet.data[packet.data.len - 1]);
}

test "eth_packet_parsing_valid_packet_with_specific_values_unpadded" {
    const allocator = testing.allocator;

    const valid_frame = [_]u8{
        0x00, 0x11, 0x22, 0x33, 0x44, 0x55, // Destination MAC
        0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, // Source MAC
        0x08, 0x00, // EtherType (IPv4)
        0x45, 0x00, 0x00, 0x28, // Start of IP header
        // Missing 46 bytes to meet minimum frame size
    };

    var packet = try Eth_Parser.parse(allocator, &valid_frame);
    defer packet.deinit(allocator);

    try testing.expectEqualSlices(u8, &[_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 }, &packet.dest);
    try testing.expectEqualSlices(u8, &[_]u8{ 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF }, &packet.source);
    try testing.expectEqualSlices(u8, &[_]u8{ 0x08, 0x00 }, &packet.packet_type);
    try testing.expectEqual(@as(usize, Eth_Data_Size_Range[0]), packet.data.len);
    try testing.expectEqual(@as(u8, 0x45), packet.data[0]);
}
