const std = @import("std");
const L2 = @import("../lib/layer2_datalink/main.zig");
const vInterface = L2.Interface_Handler.Interface;
const vSwitch = L2.Switch_Handler.Switch;
const VLAN = @import("VLAN.zig").VLAN;
// ================================================================================
// For testing / dev
// Todo: move to appropriate location

// ================================================================================
const DEFAULT_INTERFACE = "eth0";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const vlan = VLAN.init(allocator);

    const vETH0 = try vInterface.init(allocator, "eth0");
    defer vETH0.deinit();

    const vETH1 = try vInterface.init(allocator, "eth1");
    defer vETH1.deinit();

    const vETH2 = try vInterface.init(allocator, "eth2");
    defer vETH2.deinit();

    vETH0.log();
    vETH1.log();
    vETH2.log();

    const _switch = try vSwitch.init(allocator, DEFAULT_INTERFACE);
    defer _switch.deinit();

    try vlan.add_link(_switch, vETH0);
    try vlan.add_link(_switch, vETH1);
    try vlan.add_link(_switch, vETH2);
}

test "network stack & pipeline test" {
    // cases:
    // - Multiple sockets initialized
    // - memory management
    // - sending sockets
    // - max bitrate vs std lib / existing solutions
}
