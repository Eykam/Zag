const std = @import("std");
const Frame = @import("Frame.zig");
const Helpers = @import("helpers.zig");

const fs = std.fs;
const Eth_Parser = Frame.Eth_Parser;
const Eth_Frame = Frame.Eth_Frame;

const PACKET_PROTO: u32 = 0x0003; // cat /etc/protocols => IP protocol
const AF_PACKET: u32 = @as(u32, std.posix.AF.PACKET);
const SOCK_TYPE: u32 = @as(u32, std.posix.SOCK.RAW);
const IF_INDEX: i32 = 2;

// Make sure memory aligned??
// Might not need to optimized since not many sockets open at once. Linux also limits # file descriptors
pub const Switch = struct {
    socket: ?std.posix.socket_t,
    address: std.posix.sockaddr.ll,

    pub fn init(self: *Switch, interface: []const u8) !void {
        // Create a raw socket
        const socket = try std.posix.socket(AF_PACKET, SOCK_TYPE, std.mem.nativeToBig(
            u32,
            PACKET_PROTO,
        ));

        if (socket < 0) {
            std.debug.print("Error creating socket\n", .{});
            return;
        }

        std.debug.print("Raw socket created successfully!\n", .{});
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

    pub fn bind(self: *Switch) !void {
        const addr_ptr = @as(*const std.posix.sockaddr, @ptrCast(&self.address));
        try std.posix.bind(self.socket.?, addr_ptr, @sizeOf(std.posix.sockaddr.ll));
    }

    pub fn recvfrom(self: *Switch, buffer: []u8) !void {
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

    fn log(self: *Switch) !void {
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

    pub fn send(self: *Switch, sockfd: std.posix.socket_t, packet: []const u8, data_len: u8) !bool {
        _ = self;

        const flags: u32 = 0;

        var total_sent: usize = 0;
        const total_size = Frame.Eth_Header_Size + data_len;

        while (total_sent < total_size) {
            const bytes_sent = std.posix.send(sockfd, packet[total_sent..], flags) catch |err| {
                std.debug.print("Error sending frames from L2 Switch!\n {}", .{err});
                return false;
            };
            total_sent += bytes_sent;
            // std.debug.print("Sent {} bytes, total {}/{}\n", .{ bytes_sent, total_sent, total_size });
        }
        return true;
    }

    fn close() !void {} // TODO: Implement
};

test "raw_socket_operations" {}