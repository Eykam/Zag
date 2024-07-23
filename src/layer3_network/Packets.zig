const IPV4_Packet = packed struct {
    version: u4,
    header_length: u4,
    tos_ds: u8,
    packet_length: u16,
    identification: u16,
    flag: u4,
    frag_offset: u12,
    ttl: u8,
    protocol: u8,
    checksum: u16,
    source: u32,
    dest: u32,

    pub fn init(data: [5]u32) IPV4_Packet {
        _ = data;
        return @This();
    }
};

test "IPV4_test" {}
