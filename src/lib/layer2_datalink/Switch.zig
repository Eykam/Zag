const std = @import("std");
const linux = @cImport({
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
    @cInclude("sys/ioctl.h");
    @cInclude("linux/if.h");
    @cInclude("linux/if_tun.h");
});

const Helpers = @import("../utils/Helpers.zig");
const Interface_Handler = @import("Interface.zig");
const MAC = @import("./MAC.zig");
const MAC_Address_Table = MAC.MAC_Address_Table;
const Link = @import("./Link.zig").Link;

const Interface = Interface_Handler.Interface;
const Allocator = std.mem.Allocator;

const PACKET_PROTO: u32 = 0x0003; // cat /etc/protocols => IP protocol
const IF_INDEX: i32 = 2;

const AF_PACKET: u32 = @as(u32, std.posix.AF.PACKET);
const SOCK_TYPE: u32 = @as(u32, std.posix.SOCK.RAW);

pub const Switch = struct {
    const Self = @This();

    // map of associated mac_address with read/write pipe for communication between interface and switch threads
    link_mapping: std.AutoHashMap(@TypeOf(Link), std.posix.socket_t),
    MAC_Address_Table: MAC_Address_Table,
    allocator: Allocator,

    physical_link: std.posix.socket_t,
    physical_link_id: std.posix.sockaddr.ll,

    pub fn init(allocator: Allocator, trunk_port: []const u8) !Self {
        // Create a raw socket
        const physical_link = try std.posix.socket(AF_PACKET, SOCK_TYPE, std.mem.nativeToBig(
            u32,
            PACKET_PROTO,
        ));

        if (physical_link < 0) {
            std.debug.print("Error creating socket\n", .{});
            return error.SocketCreationFailure;
        }

        std.debug.print("Raw socket created successfully!\n", .{});
        const mac_addr = try Helpers.getMacAddress(trunk_port);

        // Todo: find way to get these values programmatically / at comptime
        const physical_link_id = std.posix.sockaddr.ll{
            .family = AF_PACKET,
            .protocol = std.mem.nativeToBig(u16, PACKET_PROTO),
            .ifindex = IF_INDEX,
            .hatype = 1,
            .pkttype = 0,
            .halen = 6,
            .addr = mac_addr,
        };

        return Self{
            .link_mapping = std.AutoHashMap(@TypeOf(Link), std.posix.socket_t).init(allocator),
            .MAC_Address_Table = MAC_Address_Table.init(allocator),
            .allocator = allocator,
            .physical_link = physical_link,
            .physical_link_id = physical_link_id,
        };
    }

    pub fn deinit(self: Self) !void {
        self.allocator.destroy(self.MAC_Address_Table);
    }

    fn bind(self: *Self) !void {
        const addr_ptr = @as(*const std.posix.sockaddr, @ptrCast(&self.physical_link_id));
        try std.posix.bind(self.physical_link.?, addr_ptr, @sizeOf(std.posix.sockaddr.ll));
    }

    // TODO: Implement LLCD or some broadcasting protocol to let others on network know
    // Also spawn reading of interface in new thread
    pub fn create_link(self: Self, allocator: Allocator, interface: Interface) !void {
        const link = Link.init(interface);

        _ = allocator;
        const fd = "";

        self.link_mapping.put(link, fd);
    }

    pub fn destroy_link(self: Self, link: Link) void {
        self.link_mapping.remove(link);
    }

    fn forward(self: Self) void {
        _ = self;
    }
};

test "raw_socket_operations" {}
