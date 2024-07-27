const std = @import("std");
const Allocator = std.mem.Allocator;

const MAX_PACKET_SIZE = 1500; // Standard Ethernet MTU

const MacAddress = [6]u8;
const IpAddress = [4]u8;

const EtherType = enum(u16) {
    IPv4 = 0x0800,
    ARP = 0x0806,
    // Add other EtherTypes as needed
};

const Packet = struct {
    data: []u8,
    dest_mac: MacAddress,
};

const Interface = struct {
    name: []const u8,
    mac: MacAddress,
    ip: IpAddress,
    allocator: Allocator,
    recv_queue: std.ArrayList(Packet),

    pub fn init(allocator: Allocator, name: []const u8, mac: MacAddress, ip: IpAddress) !Interface {
        return Interface{
            .name = name,
            .mac = mac,
            .ip = ip,
            .allocator = allocator,
            .recv_queue = std.ArrayList(Packet).init(allocator),
        };
    }

    pub fn deinit(self: *Interface) void {
        for (self.recv_queue.items) |packet| {
            self.allocator.free(packet.data);
        }
        self.recv_queue.deinit();
    }

    pub fn receivePacket(self: *Interface) ?Packet {
        if (self.recv_queue.items.len == 0) return null;
        return self.recv_queue.orderedRemove(0);
    }
};

const VirtualNetwork = struct {
    interfaces: std.ArrayList(Interface),
    allocator: Allocator,
    packet_queue: std.ArrayList(Packet),

    pub fn init(allocator: Allocator) VirtualNetwork {
        return VirtualNetwork{
            .interfaces = std.ArrayList(Interface).init(allocator),
            .allocator = allocator,
            .packet_queue = std.ArrayList(Packet).init(allocator),
        };
    }

    pub fn deinit(self: *VirtualNetwork) void {
        for (self.interfaces.items) |*iface| {
            iface.deinit();
        }
        self.interfaces.deinit();
        for (self.packet_queue.items) |packet| {
            self.allocator.free(packet.data);
        }
        self.packet_queue.deinit();
    }

    pub fn addInterface(self: *VirtualNetwork, name: []const u8, mac: MacAddress, ip: IpAddress) !void {
        const iface = try Interface.init(self.allocator, name, mac, ip);
        try self.interfaces.append(iface);
    }

    pub fn sendPacket(self: *VirtualNetwork, packet: []const u8, dest_mac: MacAddress) !void {
        const new_packet = Packet{
            .data = try self.allocator.alloc(u8, packet.len),
            .dest_mac = dest_mac,
        };
        @memcpy(new_packet.data, packet);
        try self.packet_queue.append(new_packet);
    }

    pub fn processPackets(self: *VirtualNetwork) !void {
        while (self.packet_queue.popOrNull()) |packet| {
            for (self.interfaces.items) |*iface| {
                if (std.mem.eql(u8, &iface.mac, &packet.dest_mac)) {
                    try iface.recv_queue.append(packet);
                    std.debug.print("Packet routed to interface: {s}\n", .{iface.name});
                    break;
                }
            }
        }
    }
};

pub fn main() !void {
    std.debug.print("Creating Virtual network...\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var network = VirtualNetwork.init(allocator);
    defer network.deinit();

    try network.addInterface("eth0", .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 }, .{ 192, 168, 1, 1 });
    try network.addInterface("eth1", .{ 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB }, .{ 192, 168, 2, 1 });
    std.debug.print("Creating Virtual Interfaces:\n", .{});

    std.debug.print("eth0: ", .{});
    inline for (network.interfaces.items[0].mac, 0..) |byte, ind| {
        const last = if (ind < network.interfaces.items[0].mac.len - 1) ":" else "";
        std.debug.print("{x:0>2}{s}", .{ byte, last });
    }

    std.debug.print("\neth1: ", .{});
    inline for (network.interfaces.items[1].mac, 0..) |byte, ind| {
        const last = if (ind < network.interfaces.items[1].mac.len - 1) ":" else "";
        std.debug.print("{x:0>2}{s}", .{ byte, last });
    }
    std.debug.print("\n", .{});

    // Simulate sending a packet
    var packet = [_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0x08, 0x00 };

    std.debug.print("Sending Packet from eth0\n", .{});
    try network.sendPacket(&packet, .{ 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB });

    // Process packets
    try network.processPackets();

    // Check if the packet was received on the other interface
    if (network.interfaces.items[1].receivePacket()) |received| {
        std.debug.print("Received packet on eth1: {any}\n", .{received.data});
        allocator.free(received.data);
    } else {
        std.debug.print("No packet received on eth1\n", .{});
    }
}
