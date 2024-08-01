const std = @import("std");
const L2 = @import("../lib/layer2_datalink/main.zig");
const L3 = @import("../lib/layer3_network/main.zig");

const Allocator = std.mem.Allocator;
const Router = L3.Router_Handler.Router;
const Switch = L2.Switch_Handler.Switch;
const Bridge = L2.Bridge_Handler.Bridge;
const Interface = L2.Interface_Handler.Interface;
const Frame = L2.Frame_Handler.Eth_Frame;

pub const VLAN = struct {
    const Self = @This();

    interfaces: std.ArrayList(Interface),
    switches: std.ArrayList(Switch),
    routers: std.ArrayList(Router),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Self {
        return Self{
            .interfaces = std.ArrayList(Interface).init(allocator),
            .switches = std.ArrayList(Switch).init(allocator),
            .routers = std.ArrayList(Router).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        for (self.interfaces.items) |*iface| {
            iface.deinit(self.allocator);
        }

        for (self.switches.items) |_switch| {
            _switch.deinit(self.allocator);
        }

        for (self.routers.items) |router| {
            router.deinit(self.allocator);
        }

        self.interfaces.deinit();
        self.switches.deinit();
        self.routers.deinit();
    }

    pub fn add_link(self: Self, _switch: Switch, interface: Interface) !void {
        try _switch.create_link(self.allocator, interface) catch return error.FailedToAddLink;
        self.interfaces.append(interface);
    }

    pub fn add_switch(self: Self, trunk_port: []const u8) !void {
        const _switch = Switch.init(self.allocator, trunk_port);
        try self.switches.append(_switch);
    }

    pub fn add_router(self: Self, router: Router) !void {
        try self.routers.append(router);
    }
};

// pub fn main() !void {
//     std.debug.print("Creating Virtual network...\n", .{});
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const allocator = gpa.allocator();

//     var network = Network.init(allocator);
//     defer network.deinit();

//     try network.addInterface("eth0", .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 }, .{ 192, 168, 1, 1 });
//     try network.addInterface("eth1", .{ 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB }, .{ 192, 168, 2, 1 });
//     std.debug.print("Creating Virtual Interfaces:\n\n", .{});

//     std.debug.print("eth0: ", .{});
//     inline for (network.interfaces.items[0].mac, 0..) |byte, ind| {
//         const last = if (ind < network.interfaces.items[0].mac.len - 1) ":" else "";
//         std.debug.print("{x:0>2}{s}", .{ byte, last });
//     }

//     std.debug.print("\neth1: ", .{});
//     inline for (network.interfaces.items[1].mac, 0..) |byte, ind| {
//         const last = if (ind < network.interfaces.items[1].mac.len - 1) ":" else "";
//         std.debug.print("{x:0>2}{s}", .{ byte, last });
//     }
//     std.debug.print("\n\n", .{});

//     // Simulate sending a packet
//     _ = [_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0x08, 0x00 };
//     _ = [_]u8{ 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99 };
// }
