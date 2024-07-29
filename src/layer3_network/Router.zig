const std = @import("std");

const Router = struct {
    ip: u8,
    mac_address: u8,
    IP_Table: std.ArrayList(u8), // Todo: implement IP Table
    ARP_Table: std.ArrayList(u8), // Todo: implement IP Table

    fn dhcp_offer() !void {}
    fn ARP_request() !void {}
    fn ARP_response() !void {}
    fn route_packet() !void {}
};
