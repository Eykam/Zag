const std = @import("std");

const Mac_Address = struct {
    const Self = @This();

    address: [6]u8,

    pub fn hash(self: Self) u64 {
        return std.hash.Wyhash.hash(0, &self.address);
    }

    pub fn eql(self: Self, other: Self) bool {
        return std.mem.eql(u8, &self.address, &other.address);
    }
};

pub const MAC_Address_Table = struct {};
