const App = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const apprt = @import("../../apprt.zig");
const CoreApp = @import("../../App.zig");
const Surface = @import("Surface.zig");
const internal_os = @import("../../os/main.zig");
const win32 = internal_os.windows.exp;
const windows = std.os.windows;

pub const must_draw_from_app_thread = false;

core_app: *CoreApp,
main_thread_id: windows.DWORD,

pub fn init(
    self: *App,
    core_app: *CoreApp,
    opts: struct {},
) !void {
    _ = opts;
    self.core_app = core_app;
    self.main_thread_id = win32.kernel32.GetCurrentThreadId();
}

pub fn run(self: *App) !void {
    try self.newWindow();

    var msg: win32.MSG = undefined;
    while (win32.user32.GetMessageW(&msg, null, 0, 0) > 0) {
        _ = win32.user32.TranslateMessage(&msg);
        _ = win32.user32.DispatchMessageW(&msg);
    }
}

pub fn newWindow(self: *App) !void {
    const h_instance = win32.kernel32.GetModuleHandleW(null) orelse return error.GetModuleHandleFailed;

    const class_name = std.unicode.utf8ToUtf16LeStringLiteral("GhosttyWindow");
    const window_name = std.unicode.utf8ToUtf16LeStringLiteral("Ghostty");

    const wc = win32.WNDCLASSEXW{
        .cbSize = @sizeOf(win32.WNDCLASSEXW),
        .style = win32.CS_HREDRAW | win32.CS_VREDRAW,
        .lpfnWndProc = wndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = h_instance,
        .hIcon = null,
        .hCursor = win32.user32.LoadCursorW(null, win32.IDC_ARROW),
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = class_name,
        .hIconSm = null,
    };

    _ = win32.user32.RegisterClassExW(&wc);

    const hwnd = win32.user32.CreateWindowExW(
        0,
        class_name,
        window_name,
        win32.WS_OVERLAPPEDWINDOW | win32.WS_VISIBLE,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        800,
        600,
        null,
        null,
        h_instance,
        null,
    ) orelse return error.CreateWindowFailed;

    // Create Surface
    const surface = try self.core_app.alloc.create(Surface);
    surface.* = .{ .hwnd = hwnd };

    // Initialize WGL
    const hdc = win32.user32.GetDC(hwnd) orelse return error.GetDCFailed;
    surface.hdc = hdc;

    var pfd = win32.PIXELFORMATDESCRIPTOR{
        .nSize = @sizeOf(win32.PIXELFORMATDESCRIPTOR),
        .nVersion = 1,
        .dwFlags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER,
        .iPixelType = win32.PFD_TYPE_RGBA,
        .cColorBits = 32,
        .cRedBits = 0, .cRedShift = 0, .cGreenBits = 0, .cGreenShift = 0, .cBlueBits = 0, .cBlueShift = 0, .cAlphaBits = 0, .cAlphaShift = 0,
        .cAccumBits = 0, .cAccumRedBits = 0, .cAccumGreenBits = 0, .cAccumBlueBits = 0, .cAccumAlphaBits = 0,
        .cDepthBits = 24,
        .cStencilBits = 8,
        .cAuxBuffers = 0,
        .iLayerType = win32.PFD_MAIN_PLANE,
        .bReserved = 0,
        .dwLayerMask = 0, .dwVisibleMask = 0, .dwDamageMask = 0,
    };

    const pixel_format = win32.gdi32.ChoosePixelFormat(hdc, &pfd);
    if (pixel_format == 0) return error.ChoosePixelFormatFailed;

    if (win32.gdi32.SetPixelFormat(hdc, pixel_format, &pfd) == 0) return error.SetPixelFormatFailed;

    const hglrc = win32.opengl32.wglCreateContext(hdc) orelse return error.WglCreateContextFailed;
    surface.hglrc = hglrc;

    if (win32.opengl32.wglMakeCurrent(hdc, hglrc) == 0) return error.WglMakeCurrentFailed;

    // Store surface in window data
    _ = win32.user32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, @intCast(@intFromPtr(surface)));

    // Create CoreSurface
    const core_surface = try self.core_app.alloc.create(CoreApp.Surface);
    try core_surface.init(
        self.core_app.alloc,
        self.core_app.config,
        self.core_app,
        self,
        surface,
    );
    surface.core_surface = core_surface;

    // Release context so render thread can use it
    if (win32.opengl32.wglMakeCurrent(hdc, null) == 0) return error.WglMakeCurrentFailed;

    _ = win32.user32.ShowWindow(hwnd, win32.SW_SHOW);
    _ = win32.user32.UpdateWindow(hwnd);
}

fn wndProc(
    hwnd: windows.HWND,
    u_msg: windows.UINT,
    w_param: windows.WPARAM,
    l_param: windows.LPARAM,
) callconv(windows.WINAPI) windows.LRESULT {
    const ptr = win32.user32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA);
    const surface: ?*Surface = if (ptr != 0) @ptrFromInt(@as(usize, @intCast(ptr))) else null;

    switch (u_msg) {
        win32.WM_SIZE => {
            if (surface) |s| {
                 const width: u32 = @intCast(l_param & 0xFFFF);
                 const height: u32 = @intCast((l_param >> 16) & 0xFFFF);
                 s.core_surface.sizeCallback(.{ .width = width, .height = height }) catch {};
            }
             return 0;
        },
        win32.WM_CHAR => {
             if (surface) |s| {
                  var utf16: [1]u16 = .{ @intCast(w_param) };
                  var utf8: [4]u8 = undefined;
                  const len = std.unicode.utf16leToUtf8(&utf8, &utf16) catch 0;
                  if (len > 0) {
                       s.core_surface.textCallback(utf8[0..len]) catch {};
                  }
             }
             return 0;
        },
        win32.WM_DESTROY => {
            win32.user32.PostQuitMessage(0);
            return 0;
        },
        else => return win32.user32.DefWindowProcW(hwnd, u_msg, w_param, l_param),
    }
}

pub fn terminate(self: *App) void {
    _ = self;
}

pub fn wakeup(self: *App) void {
    _ = win32.user32.PostThreadMessageW(self.main_thread_id, win32.WM_NULL, 0, 0);
}

pub fn performAction(
    self: *App,
    target: apprt.Target,
    comptime action: apprt.Action.Key,
    value: apprt.Action.Value(action),
) !bool {
    _ = self;
    switch (target) {
        .app => {},
        .surface => |s| {
             const surf = @as(*Surface, @ptrCast(s));
             _ = surf;
        },
    }

    switch (action) {
        .initial_size => {
            if (target == .surface) {
                 _ = value;
            }
            return true;
        },
        else => {},
    }
    return false;
}

pub fn performIpc(
    alloc: Allocator,
    target: apprt.ipc.Target,
    comptime action: apprt.ipc.Action.Key,
    value: apprt.ipc.Action.Value(action),
) !bool {
    _ = alloc;
    _ = target;
    _ = value;
    return false;
}

pub fn redrawInspector(_: *App, surface: *Surface) void {
    surface.redrawInspector();
}
