const std = @import("std");

var src_addr: std.posix.sockaddr.ll = undefined;
const src_addr_ptr = @as(*std.posix.sockaddr, @ptrCast(&src_addr));
