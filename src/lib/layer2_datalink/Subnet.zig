const std = @import("std");

pub const Subnet_Entry = struct {
    subnet: u8,
    subnet_mask: u8,
    ip_range: u8,
    vlan_id: u8,
    description: u8,
};

pub const Subnet_Table = std.ArrayList(Subnet_Entry);
