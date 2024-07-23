const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

pub const EthPacketSizeRange = .{ 64, 1518 };

pub const Eth_Packet = struct {
    dest: [6]u8,
    source: [6]u8,
    packet_type: [2]u8,
    data: []u8,
    crc: [4]u8,

    pub fn deinit(self: *Eth_Packet, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn log(self: *Eth_Packet, data_len: usize) void {
        print("===============================\n", .{});
        print("Received {} bytes\n", .{data_len});

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
        print("\n\n", .{});

        for (0..data_len) |ind| {
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
        // hide my IP / MAC address when posting logged output on twitter.
    }
};

// TODO: Figure out what to do in the case that ethernet packet is less than 64 bytes
//       Double check to make sure that 64 bytes is the correct min length of eth frame
pub const Eth_Parser = struct {
    pub fn parse(allocator: std.mem.Allocator, raw_data: []const u8) !Eth_Packet {
        if (raw_data.len < 6 + 6 + 2 + 4) {
            return error.PacketTooSmall;
        }

        var packet = Eth_Packet{
            .dest = undefined,
            .source = undefined,
            .packet_type = undefined,
            .data = undefined,
            .crc = undefined,
        };

        @memcpy(&packet.dest, raw_data[0..6]);
        @memcpy(&packet.source, raw_data[6..12]);
        @memcpy(&packet.packet_type, raw_data[12..14]);

        const data_start = packet.dest.len + packet.source.len + packet.packet_type.len;
        const data_end = raw_data.len - packet.crc.len; // Last 4 bytes are CRC
        const data_len = data_end - data_start;

        // print("{} {} {}", .{ data_start, data_end, data_len });

        packet.data = try allocator.alloc(u8, data_len);

        @memcpy(packet.data, raw_data[data_start..data_end]);
        @memcpy(&packet.crc, raw_data[data_end..]);

        packet.log(data_len);

        return packet;
    }
};

test "eth_packet_parsing" {}
