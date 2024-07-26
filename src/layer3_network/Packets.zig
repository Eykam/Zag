const std = @import("std");
const assert = std.debug.assert;

const IPV4_Protocols = enum(u8) {
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

const IPV4_Packet = packed struct {
    const Self = @This();
    const VERSION_NUMBER = 0b0100;

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
    source: [4]u8,
    dest: [4]u8,

    pub fn init(raw_frame: ?[5]u32) Self {
        if (raw_frame == null) {
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
        } else {
            const version = raw_frame[0][0..4];
            assert(version == VERSION_NUMBER);

            return Self{
                .version = version,
                .header_length = raw_frame[0][4..8],
                .tos_ds = raw_frame[0][8..16],
                .packet_length = raw_frame[0][16..32],
                .identification = raw_frame[1][0..16],
                .flags = raw_frame[1][16..20],
                .frag_offset = raw_frame[1][20..32],
                .ttl = raw_frame[2][0..8],
                .protocol = raw_frame[2][8..16],
                .checksum = raw_frame[2][16..32],
                .source = raw_frame[3],
                .dest = raw_frame[4],
            };
        }
    }
    pub fn log() void {}
};

const IPV6_Packet = packed struct {
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

    pub fn init(raw_frame: ?[]u8) Self {
        if (raw_frame == null) {
            return Self{
                .version = VERSION_NUMBER,
                .traffic_class = 0,
                .flow_label = 0,
                .payload_length = 0,
                .next_header = 0,
                .source = 0,
                .dest = 0,
            };
        } else {
            assert(@sizeOf(raw_frame) >= @sizeOf([10]u32));

            const version = raw_frame[0][0..4];
            assert(version == VERSION_NUMBER);

            return Self{
                .version = raw_frame[0][0..4],
                .traffic_class = raw_frame[0][4..12],
                .flow_label = raw_frame[0][12..32],
                .payload_length = raw_frame[1][0..16],
                .next_header = raw_frame[1][16..24],
                .hop_limit = raw_frame[1][24..32],
                .source = raw_frame[2..6],
                .dest = raw_frame[6..10],
            };
        }
    }
    pub fn log() void {}
};

const ARP_Packet = packed struct {
    pub fn init() void {}
};
const LLDP_Packet = packed struct {
    pub fn init() void {}
};

test "IPV4_test" {}
