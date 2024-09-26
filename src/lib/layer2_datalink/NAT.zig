const std = @import("std");
const Packets = @import("../layer3_network/Packets.zig");
const IPv4 = Packets.IPv4_Packet;
const IPv4_Address = IPv4.IPv4_Address;

// =====================================================================================================
// Internal IP	    Internal Port	External IP	    External Port	Destination IP	    Destination Port
// =====================================================================================================
// 192.168.1.2	    1025	        203.0.113.5	    40000	        93.184.216.34	    80
// 192.168.1.3	    1026	        203.0.113.5	    40001   	    93.184.216.34	    80
// 192.168.1.4	    1027	        203.0.113.5	    40002	        192.0.2.123	443
// 192.168.1.2	    1028	        203.0.113.5	    40003	        198.51.100.45	    21

pub const NAT_Entry = struct {
    internal_IP: IPv4_Address,
    internal_port: u8,

    external_IP: IPv4_Address,
    external_port: u8,

    dest_IP: IPv4_Address,
    dest_port: u8,
};

pub const NAT_List = std.ArrayList(NAT_Entry);

pub const NAT_Table = struct {
    const Self = @This();

    values: NAT_List,

    pub fn find(self: *Self, IP: IPv4_Address) void {
        _ = self;
        _ = IP;
    }
};

// ===================================================== Tests ======================================================

const testing = std.testing;

test {}
