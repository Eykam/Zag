const std = @import("std");
const Frame = @import("L2").Frame_Handler.Eth_Frame;
const assert = std.debug.assert;

pub const IPv4_Packet = packed struct {
    const Self = @This();
    const VERSION_NUMBER = 0b0100;
    const IPv4_Address = u32;

    const Supported_Protocols = enum(u8) {
        TCP = 0x06,
        UDP = 0x11,
        ICMP = 0x01,
        IGMP = 0x02,
        ESP = 0x32,
        AH = 0x33,
        IPv6 = 0x29,
        GRE = 0x2F,
        OSPF = 0x59,
    };

    version: u4,
    header_length: u4,
    tos_ds: u8,
    packet_length: u16,
    identification: u16,
    flags: u4,
    frag_offset: u12,
    ttl: u8,
    protocol: u8,
    checksum: u16,
    source: IPv4_Address,
    dest: IPv4_Address,

    pub fn init() Self {
        return Self{
            .version = VERSION_NUMBER,
            .header_length = 0,
            .tos_ds = 0,
            .packet_length = 0,
            .identification = 0,
            .flag = 0,
            .frag_offset = 0,
            .ttl = 0,
            .protocol = 0,
            .checksum = 0,
            .source = 0,
            .dest = 0,
        };
    }

    pub fn unpack(raw_frame: Frame) Self {
        const packet_data = raw_frame.data;

        const version: u4 = @as(u4, @intCast((packet_data[0] >> 4) & 0xF));
        assert(version == VERSION_NUMBER);

        const header_length: u4 = @as(u4, @intCast(packet_data[0] & 0x0F));
        const tos_ds = packet_data[1];

        const packet_length: u12 = @as(u8, @intCast((packet_data[2]) << 8)) ++ @as(u4, @intCast(packet_data[3] >> 4));
        const identification: u16 = (@as(u16, packet_data[4]) << 8) | @as(u16, packet_data[5]);

        const flags: u4 = @as(u4, @intCast((packet_data[6] >> 5) & 0x7));
        const frag_offset: u12 = (@as(u16, packet_data[6] & 0x1F) << 8) | @as(u16, packet_data[7]);

        const ttl = packet_data[8];
        const protocol = packet_data[9];

        const checksum: u16 = (@as(u16, packet_data[10]) << 8) | @as(u16, packet_data[11]);
        const source: IPv4_Address = (@as(IPv4_Address, packet_data[12]) << 24) | (@as(IPv4_Address, packet_data[13]) << 16) | (@as(IPv4_Address, packet_data[14]) << 8) | @as(IPv4_Address, packet_data[15]);
        const dest: IPv4_Address = (@as(IPv4_Address, packet_data[16]) << 24) | (@as(IPv4_Address, packet_data[17]) << 16) | (@as(IPv4_Address, packet_data[18]) << 8) | @as(IPv4_Address, packet_data[19]);

        return Self{
            .version = version,
            .header_length = header_length,
            .tos_ds = tos_ds,
            .packet_length = packet_length,
            .identification = identification,
            .flags = flags,
            .frag_offset = frag_offset,
            .ttl = ttl,
            .protocol = protocol,
            .checksum = checksum,
            .source = source,
            .dest = dest,
        };
    }

    pub fn log() void {}
};

pub const IPv6_Packet = packed struct {
    const Self = @This();
    const VERSION_NUMBER = 0b0110;

    version: u4,
    traffic_class: u8,
    flow_label: u20,
    payload_length: u16,
    next_header: u8,
    hop_limit: u8,
    source: [4][2]u16,
    dest: [4][2]u16,

    pub fn init() Self {
        return Self{
            .version = VERSION_NUMBER,
            .traffic_class = 0,
            .flow_label = 0,
            .payload_length = 0,
            .next_header = 0,
            .source = 0,
            .dest = 0,
        };
    }

    pub fn unpack(raw_frame: Frame) Self {
        const packet_data = raw_frame.data;
        const version = packet_data[0][0..4];
        assert(version == VERSION_NUMBER);

        return Self{
            .version = packet_data[0][0..4],
            .traffic_class = packet_data[0][4..12],
            .flow_label = packet_data[0][12..32],
            .payload_length = packet_data[1][0..16],
            .next_header = packet_data[1][16..24],
            .hop_limit = packet_data[1][24..32],
            .source = packet_data[2..6],
            .dest = packet_data[6..10],
        };
    }

    pub fn log() void {}
};

pub const ARP_Packet = packed struct {
    pub fn init() void {}
    pub fn unpack(raw_frame: Frame) void {
        _ = raw_frame;
    }
};

pub const LLDP_Packet = packed struct {
    pub fn init() void {}
    pub fn unpack(raw_frame: Frame) void {
        _ = raw_frame;
    }
};

test "IPV4_test" {}
