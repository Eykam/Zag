const std = @import("std");

pub const MAC_Address = struct {
    const Self = @This();

    address: u48,

    pub fn hash(self: Self) u64 {
        return std.hash.Wyhash.hash(0, &self.address);
    }

    pub fn eql(self: Self, other: Self) bool {
        return std.mem.eql(u8, &self.address, &other.address);
    }
};

pub const MAC_Address_Table = std.AutoHashMap(MAC_Address, std.posix.socket_t);
