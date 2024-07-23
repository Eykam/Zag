const std = @import("std");
const assert = std.debug.assert;
const EthPacketSizeRange = .{ 64, 1518 };

pub const Eth_Packet = struct {
    dest: [6]u8,
    source: [6]u8,
    type: [2]u8,
    data: [*]u8,
    // crc: u4,

    pub fn init(self: *Eth_Packet, data: []u8, len: u16) !void {
        std.debug.print("Packet Length: {}, Min: {}, Max: {}\n", .{ len, EthPacketSizeRange[0], EthPacketSizeRange[1] });
        assert(EthPacketSizeRange[0] < len and len < EthPacketSizeRange[1]);

        var offset: usize = 0;

        // std.debug.print("Data: {x}\n", .{data.*});

        const dest_len = @sizeOf(@TypeOf(self.dest));
        @memcpy(self.dest[0..], data[offset..(offset + dest_len)]);
        offset += dest_len;
        // std.debug.print("Offset: {}\n", .{offset});

        const source_len = @sizeOf(@TypeOf(self.source));
        @memcpy(self.source[0..], data[offset..(offset + source_len)]);
        offset += source_len;
        // std.debug.print("Offset: {}\n", .{offset});

        const type_len = @sizeOf(@TypeOf(self.type));
        @memcpy(self.type[0..], data[offset..(offset + type_len)]);
        offset += type_len;
        // std.debug.print("Offset: {}\n", .{offset});

        // const data_len = len - offset;
        // @memcpy(self.data[0..data_len], data.*[offset..(offset + data_len)]);
    }

    pub fn parse(self: *Eth_Packet) !void {
        _ = self;
    }
};

pub const IPV4_Packet = struct {};
pub const IPV6_Packet = struct {};
pub const UDP_Packet = struct {};
