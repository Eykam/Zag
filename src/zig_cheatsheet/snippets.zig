const std = @import("std");
// ========================================================================

var src_addr: std.posix.sockaddr.ll = undefined;
const src_addr_ptr = @as(*std.posix.sockaddr, @ptrCast(&src_addr));

// ========================================================================

const packet_type = [2]u8;
const packet_typ_u16 = @as(u16, packet_type[0]) << 8 | packet_type[1];
