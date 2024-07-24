const std = @import("std");
const Packets = @import("Packets.zig");
const Helpers = @import("helpers.zig");

const fs = std.fs;
const Eth_Parser = Packets.Eth_Parser;
const Eth_Packet = Packets.Eth_Packet;

const PACKET_PROTO: u32 = 0x0003; // cat /etc/protocols => IP protocol
const AF_PACKET: u32 = @as(u32, std.posix.AF.PACKET);
const SOCK_TYPE: u32 = @as(u32, std.posix.SOCK.RAW);
const IF_INDEX: i32 = 2;

// Rename to switch??
// Make sure memory aligned??
// Might not need to optimized since not many sockets open at once. Linux also limits # file descriptors
pub const Raw_Socket = struct {
    socket: ?std.posix.socket_t,
    address: std.posix.sockaddr.ll,
    pub fn init(self: *Raw_Socket, interface: []const u8) !void {
        // Create a raw socket
        const socket = try std.posix.socket(AF_PACKET, SOCK_TYPE, std.mem.nativeToBig(
            u32,
            PACKET_PROTO,
        ));

        if (socket < 0) {
            std.debug.print("Error creating socket\n", .{});
            return;
        }

        const mac_addr = try Helpers.getMacAddress(interface);

        // Todo: find way to get these values programmatically / at comptime
        self.address = std.posix.sockaddr.ll{
            .family = AF_PACKET,
            .protocol = std.mem.nativeToBig(u16, PACKET_PROTO),
            .ifindex = IF_INDEX,
            .hatype = 1,
            .pkttype = 0,
            .halen = 6,
            .addr = mac_addr,
        };

        self.socket = socket;
        try self.log();
        return;
    }

    pub fn bind(self: *Raw_Socket) !void {
        const addr_ptr = @as(*const std.posix.sockaddr, @ptrCast(&self.address));
        try std.posix.bind(self.socket.?, addr_ptr, @sizeOf(std.posix.sockaddr.ll));
    }

    pub fn recvfrom(self: *Raw_Socket, buffer: []u8) !void {
        var src_addr: std.posix.sockaddr.ll = undefined;
        var addr_len: std.posix.socklen_t = @sizeOf(std.posix.sockaddr.ll);
        const src_addr_ptr = @as(*std.posix.sockaddr, @ptrCast(&src_addr));

        _ = try std.posix.recvfrom(
            self.socket.?,
            buffer,
            0,
            src_addr_ptr,
            &addr_len,
        );

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        var curr_packet = try Eth_Parser.parse(allocator, buffer);
        defer curr_packet.deinit(allocator);

        // get list of types from libc. Switch statement over
        // types w/ L3 packet parser to process each.
        const packet_typ_u16 = @as(u16, curr_packet.packet_type[0]) << 8 | curr_packet.packet_type[1];
        switch (packet_typ_u16) {
            // IPv4
            0x0800 => {
                std.debug.print("==== Found IPV4 Packet! ====\n", .{});
            },
            // IPV6, ARP, etc...
            else => {},
        }
    }

    pub fn log(self: *Raw_Socket) !void {
        std.debug.print("Raw socket created successfully!\n", .{});
        std.debug.print("Socket ID:{?}\nInterface: ", .{self.socket});
        inline for (self.address.addr, 0..) |byte, ind| {
            const last = if (ind < self.address.addr.len - 1) ":" else "";
            std.debug.print("{x:0>2}{s}", .{
                byte,
                last,
            });
        }
        std.debug.print("\n", .{});
    }

    pub fn sendTo() !void {} // TODO: Implement
    pub fn close() !void {} // TODO: Implement
};

test "raw_socket_operations" {}
