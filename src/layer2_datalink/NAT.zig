const std = @import("std");
const L3 = @import("L3");
const Packets = L3.Packets;
// =====================================================================================================
// Internal IP	    Internal Port	External IP	    External Port	Destination IP	    Destination Port
// =====================================================================================================
// 192.168.1.2	    1025	        203.0.113.5	    40000	        93.184.216.34	    80
// 192.168.1.3	    1026	        203.0.113.5	    40001   	    93.184.216.34	    80
// 192.168.1.4	    1027	        203.0.113.5	    40002	        192.0.2.123	443
// 192.168.1.2	    1028	        203.0.113.5	    40003	        198.51.100.45	    21

pub const NAT_Entry = struct {
    internal_IP: Packets.IPv4,
    internal_port: []u8,

    external_IP: [4]u8,
    external_port: u8,

    dest_IP: [4]u8,
    dest_port: u8,
};

pub const NAT_Table = std.ArrayList(NAT_Entry);

// ===================================================== Tests ======================================================

const testing = std.testing;

test {}
