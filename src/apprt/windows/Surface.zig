const Self = @This();

const std = @import("std");
const apprt = @import("../../apprt.zig");
const CoreSurface = @import("../../Surface.zig");
const ApprtApp = @import("App.zig");
const windows = std.os.windows;
const internal_os = @import("../../os/main.zig");
const win32 = internal_os.windows.exp;
const HGLRC = internal_os.windows.HGLRC;

core_surface: *CoreSurface = undefined,
hwnd: windows.HWND = undefined,
hglrc: ?HGLRC = null,
hdc: ?windows.HDC = null,

pub fn deinit(self: *Self) void {
    if (self.hglrc) |rc| {
        _ = win32.opengl32.wglDeleteContext(rc);
    }
    if (self.hdc) |dc| {
        _ = win32.user32.ReleaseDC(self.hwnd, dc);
    }
}

pub fn core(self: *Self) *CoreSurface {
    return self.core_surface;
}

pub fn rtApp(self: *Self) *ApprtApp {
    return @ptrCast(self.core_surface.rt_app);
}

pub fn close(self: *Self, process_active: bool) void {
    _ = process_active;
    _ = win32.user32.DestroyWindow(self.hwnd);
}

pub fn cgroup(self: *Self) ?[]const u8 {
    _ = self;
    return null;
}

pub fn getTitle(self: *Self) ?[:0]const u8 {
    // TODO: Get title from window
    _ = self;
    return "Ghostty";
}

pub fn getContentScale(self: *const Self) !apprt.ContentScale {
    _ = self;
    // TODO: Get DPI scale
    return .{ .x = 1.0, .y = 1.0 };
}

pub fn getSize(self: *const Self) !apprt.SurfaceSize {
    var rect: windows.RECT = undefined;
    if (win32.user32.GetClientRect(self.hwnd, &rect) == 0) {
        return error.GetClientRectFailed;
    }
    return .{
        .width = @intCast(rect.right - rect.left),
        .height = @intCast(rect.bottom - rect.top),
    };
}

pub fn getCursorPos(self: *const Self) !apprt.CursorPos {
    var point: win32.POINT = undefined;
    if (win32.user32.GetCursorPos(&point) == 0) {
        return error.GetCursorPosFailed;
    }
    if (win32.user32.ScreenToClient(self.hwnd, &point) == 0) {
        return error.ScreenToClientFailed;
    }
    return .{ .x = @floatFromInt(point.x), .y = @floatFromInt(point.y) };
}

pub fn supportsClipboard(
    self: *const Self,
    clipboard_type: apprt.Clipboard,
) bool {
    _ = self;
    return switch (clipboard_type) {
        .standard => true,
        else => false,
    };
}

pub fn clipboardRequest(
    self: *Self,
    clipboard_type: apprt.Clipboard,
    state: apprt.ClipboardRequest,
) !void {
    _ = self;
    _ = clipboard_type;
    _ = state;
}

pub fn setClipboard(
    self: *Self,
    clipboard_type: apprt.Clipboard,
    contents: []const apprt.ClipboardContent,
    confirm: bool,
) !void {
    _ = self;
    _ = clipboard_type;
    _ = contents;
    _ = confirm;
}

pub fn defaultTermioEnv(self: *Self) !std.process.EnvMap {
    return internal_os.getEnvMap(self.core_surface.alloc);
}

pub fn redrawInspector(self: *Self) void {
    _ = self;
}
