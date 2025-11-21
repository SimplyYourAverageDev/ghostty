const std = @import("std");
const windows = std.os.windows;

// Export any constants or functions we need from the Windows API so
// we can just import one file.
pub const kernel32 = windows.kernel32;
pub const unexpectedError = windows.unexpectedError;
pub const OpenFile = windows.OpenFile;
pub const CloseHandle = windows.CloseHandle;
pub const GetCurrentProcessId = windows.GetCurrentProcessId;
pub const SetHandleInformation = windows.SetHandleInformation;
pub const DWORD = windows.DWORD;
pub const FILE_ATTRIBUTE_NORMAL = windows.FILE_ATTRIBUTE_NORMAL;
pub const FILE_FLAG_OVERLAPPED = windows.FILE_FLAG_OVERLAPPED;
pub const FILE_SHARE_READ = windows.FILE_SHARE_READ;
pub const GENERIC_READ = windows.GENERIC_READ;
pub const HANDLE = windows.HANDLE;
pub const HANDLE_FLAG_INHERIT = windows.HANDLE_FLAG_INHERIT;
pub const INFINITE = windows.INFINITE;
pub const INVALID_HANDLE_VALUE = windows.INVALID_HANDLE_VALUE;
pub const OPEN_EXISTING = windows.OPEN_EXISTING;
pub const PIPE_ACCESS_OUTBOUND = windows.PIPE_ACCESS_OUTBOUND;
pub const PIPE_TYPE_BYTE = windows.PIPE_TYPE_BYTE;
pub const PROCESS_INFORMATION = windows.PROCESS_INFORMATION;
pub const S_OK = windows.S_OK;
pub const SECURITY_ATTRIBUTES = windows.SECURITY_ATTRIBUTES;
pub const STARTUPINFOW = windows.STARTUPINFOW;
pub const STARTF_USESTDHANDLES = windows.STARTF_USESTDHANDLES;
pub const SYNCHRONIZE = windows.SYNCHRONIZE;
pub const WAIT_FAILED = windows.WAIT_FAILED;
pub const FALSE = windows.FALSE;
pub const TRUE = windows.TRUE;

pub const exp = struct {
    pub const HPCON = windows.LPVOID;

    pub const CREATE_UNICODE_ENVIRONMENT = 0x00000400;
    pub const EXTENDED_STARTUPINFO_PRESENT = 0x00080000;
    pub const LPPROC_THREAD_ATTRIBUTE_LIST = ?*anyopaque;
    pub const FILE_FLAG_FIRST_PIPE_INSTANCE = 0x00080000;

    pub const STATUS_PENDING = 0x00000103;
    pub const STILL_ACTIVE = STATUS_PENDING;

    pub const STARTUPINFOEX = extern struct {
        StartupInfo: windows.STARTUPINFOW,
        lpAttributeList: LPPROC_THREAD_ATTRIBUTE_LIST,
    };

    pub const kernel32 = struct {
        pub extern "kernel32" fn CreatePipe(
            hReadPipe: *windows.HANDLE,
            hWritePipe: *windows.HANDLE,
            lpPipeAttributes: ?*const windows.SECURITY_ATTRIBUTES,
            nSize: windows.DWORD,
        ) callconv(windows.WINAPI) windows.BOOL;
        pub extern "kernel32" fn CreatePseudoConsole(
            size: windows.COORD,
            hInput: windows.HANDLE,
            hOutput: windows.HANDLE,
            dwFlags: windows.DWORD,
            phPC: *HPCON,
        ) callconv(windows.WINAPI) windows.HRESULT;
        pub extern "kernel32" fn ResizePseudoConsole(hPC: HPCON, size: windows.COORD) callconv(windows.WINAPI) windows.HRESULT;
        pub extern "kernel32" fn ClosePseudoConsole(hPC: HPCON) callconv(windows.WINAPI) void;
        pub extern "kernel32" fn InitializeProcThreadAttributeList(
            lpAttributeList: LPPROC_THREAD_ATTRIBUTE_LIST,
            dwAttributeCount: windows.DWORD,
            dwFlags: windows.DWORD,
            lpSize: *windows.SIZE_T,
        ) callconv(windows.WINAPI) windows.BOOL;
        pub extern "kernel32" fn UpdateProcThreadAttribute(
            lpAttributeList: LPPROC_THREAD_ATTRIBUTE_LIST,
            dwFlags: windows.DWORD,
            Attribute: windows.DWORD_PTR,
            lpValue: windows.PVOID,
            cbSize: windows.SIZE_T,
            lpPreviousValue: ?windows.PVOID,
            lpReturnSize: ?*windows.SIZE_T,
        ) callconv(windows.WINAPI) windows.BOOL;
        pub extern "kernel32" fn PeekNamedPipe(
            hNamedPipe: windows.HANDLE,
            lpBuffer: ?windows.LPVOID,
            nBufferSize: windows.DWORD,
            lpBytesRead: ?*windows.DWORD,
            lpTotalBytesAvail: ?*windows.DWORD,
            lpBytesLeftThisMessage: ?*windows.DWORD,
        ) callconv(windows.WINAPI) windows.BOOL;
        // Duplicated here because lpCommandLine is not marked optional in zig std
        pub extern "kernel32" fn CreateProcessW(
            lpApplicationName: ?windows.LPWSTR,
            lpCommandLine: ?windows.LPWSTR,
            lpProcessAttributes: ?*windows.SECURITY_ATTRIBUTES,
            lpThreadAttributes: ?*windows.SECURITY_ATTRIBUTES,
            bInheritHandles: windows.BOOL,
            dwCreationFlags: windows.DWORD,
            lpEnvironment: ?*anyopaque,
            lpCurrentDirectory: ?windows.LPWSTR,
            lpStartupInfo: *windows.STARTUPINFOW,
            lpProcessInformation: *windows.PROCESS_INFORMATION,
        ) callconv(windows.WINAPI) windows.BOOL;
        pub extern "kernel32" fn GetModuleHandleW(lpModuleName: ?windows.LPCWSTR) callconv(windows.WINAPI) ?windows.HINSTANCE;
        pub extern "kernel32" fn GetCurrentThreadId() callconv(windows.WINAPI) windows.DWORD;
    };

    pub const PROC_THREAD_ATTRIBUTE_NUMBER = 0x0000FFFF;
    pub const PROC_THREAD_ATTRIBUTE_THREAD = 0x00010000;
    pub const PROC_THREAD_ATTRIBUTE_INPUT = 0x00020000;
    pub const PROC_THREAD_ATTRIBUTE_ADDITIVE = 0x00040000;

    pub const ProcThreadAttributeNumber = enum(windows.DWORD) {
        ProcThreadAttributePseudoConsole = 22,
        _,
    };

    /// Corresponds to the ProcThreadAttributeValue define in WinBase.h
    pub fn ProcThreadAttributeValue(
        comptime attribute: ProcThreadAttributeNumber,
        comptime thread: bool,
        comptime input: bool,
        comptime additive: bool,
    ) windows.DWORD {
        return (@intFromEnum(attribute) & PROC_THREAD_ATTRIBUTE_NUMBER) |
            (if (thread) PROC_THREAD_ATTRIBUTE_THREAD else 0) |
            (if (input) PROC_THREAD_ATTRIBUTE_INPUT else 0) |
            (if (additive) PROC_THREAD_ATTRIBUTE_ADDITIVE else 0);
    }

    pub const PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE = ProcThreadAttributeValue(.ProcThreadAttributePseudoConsole, false, true, false);

    pub const user32 = struct {
        pub extern "user32" fn RegisterClassExW(lpwcx: *const WNDCLASSEXW) callconv(windows.WINAPI) windows.ATOM;
        pub extern "user32" fn CreateWindowExW(
            dwExStyle: windows.DWORD,
            lpClassName: windows.LPCWSTR,
            lpWindowName: windows.LPCWSTR,
            dwStyle: windows.DWORD,
            x: i32,
            y: i32,
            nWidth: i32,
            nHeight: i32,
            hWndParent: ?windows.HWND,
            hMenu: ?windows.HMENU,
            hInstance: ?windows.HINSTANCE,
            lpParam: ?windows.LPVOID,
        ) callconv(windows.WINAPI) ?windows.HWND;
        pub extern "user32" fn DefWindowProcW(
            hWnd: windows.HWND,
            Msg: windows.UINT,
            wParam: windows.WPARAM,
            lParam: windows.LPARAM,
        ) callconv(windows.WINAPI) windows.LRESULT;
        pub extern "user32" fn GetMessageW(
            lpMsg: *MSG,
            hWnd: ?windows.HWND,
            wMsgFilterMin: windows.UINT,
            wMsgFilterMax: windows.UINT,
        ) callconv(windows.WINAPI) windows.BOOL;
        pub extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(windows.WINAPI) windows.BOOL;
        pub extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(windows.WINAPI) windows.LRESULT;
        pub extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(windows.WINAPI) void;
        pub extern "user32" fn ShowWindow(hWnd: windows.HWND, nCmdShow: i32) callconv(windows.WINAPI) windows.BOOL;
        pub extern "user32" fn UpdateWindow(hWnd: windows.HWND) callconv(windows.WINAPI) windows.BOOL;
        pub extern "user32" fn LoadCursorW(hInstance: ?windows.HINSTANCE, lpCursorName: windows.LPCWSTR) callconv(windows.WINAPI) ?windows.HCURSOR;
        pub extern "user32" fn DestroyWindow(hWnd: windows.HWND) callconv(windows.WINAPI) windows.BOOL;
        pub extern "user32" fn GetClientRect(hWnd: windows.HWND, lpRect: *windows.RECT) callconv(windows.WINAPI) windows.BOOL;
        pub extern "user32" fn GetCursorPos(lpPoint: *POINT) callconv(windows.WINAPI) windows.BOOL;
        pub extern "user32" fn ScreenToClient(hWnd: windows.HWND, lpPoint: *POINT) callconv(windows.WINAPI) windows.BOOL;
        pub extern "user32" fn SetWindowLongPtrW(hWnd: windows.HWND, nIndex: i32, dwNewLong: windows.LONG_PTR) callconv(windows.WINAPI) windows.LONG_PTR;
        pub extern "user32" fn GetWindowLongPtrW(hWnd: windows.HWND, nIndex: i32) callconv(windows.WINAPI) windows.LONG_PTR;
        pub extern "user32" fn GetDC(hWnd: ?windows.HWND) callconv(windows.WINAPI) ?windows.HDC;
        pub extern "user32" fn ReleaseDC(hWnd: ?windows.HWND, hDC: windows.HDC) callconv(windows.WINAPI) i32;
        pub extern "user32" fn PostThreadMessageW(idThread: windows.DWORD, Msg: windows.UINT, wParam: windows.WPARAM, lParam: windows.LPARAM) callconv(windows.WINAPI) windows.BOOL;
    };

    pub const gdi32 = struct {
        pub extern "gdi32" fn ChoosePixelFormat(hdc: windows.HDC, ppfd: *const PIXELFORMATDESCRIPTOR) callconv(windows.WINAPI) i32;
        pub extern "gdi32" fn SetPixelFormat(hdc: windows.HDC, format: i32, ppfd: *const PIXELFORMATDESCRIPTOR) callconv(windows.WINAPI) windows.BOOL;
        pub extern "gdi32" fn SwapBuffers(hdc: windows.HDC) callconv(windows.WINAPI) windows.BOOL;
    };

    pub const opengl32 = struct {
        pub extern "opengl32" fn wglCreateContext(hdc: windows.HDC) callconv(windows.WINAPI) ?windows.HGLRC;
        pub extern "opengl32" fn wglMakeCurrent(hdc: windows.HDC, hglrc: ?windows.HGLRC) callconv(windows.WINAPI) windows.BOOL;
        pub extern "opengl32" fn wglGetProcAddress(lpszProc: windows.LPCSTR) callconv(windows.WINAPI) ?windows.PROC;
        pub extern "opengl32" fn wglDeleteContext(hglrc: windows.HGLRC) callconv(windows.WINAPI) windows.BOOL;
        pub extern "opengl32" fn wglGetCurrentDC() callconv(windows.WINAPI) ?windows.HDC;
    };

    pub const PIXELFORMATDESCRIPTOR = extern struct {
        nSize: u16 = @sizeOf(PIXELFORMATDESCRIPTOR),
        nVersion: u16 = 1,
        dwFlags: u32,
        iPixelType: u8,
        cColorBits: u8,
        cRedBits: u8,
        cRedShift: u8,
        cGreenBits: u8,
        cGreenShift: u8,
        cBlueBits: u8,
        cBlueShift: u8,
        cAlphaBits: u8,
        cAlphaShift: u8,
        cAccumBits: u8,
        cAccumRedBits: u8,
        cAccumGreenBits: u8,
        cAccumBlueBits: u8,
        cAccumAlphaBits: u8,
        cDepthBits: u8,
        cStencilBits: u8,
        cAuxBuffers: u8,
        iLayerType: u8,
        bReserved: u8,
        dwLayerMask: u32,
        dwVisibleMask: u32,
        dwDamageMask: u32,
    };

    pub const PFD_DRAW_TO_WINDOW = 0x00000004;
    pub const PFD_SUPPORT_OPENGL = 0x00000020;
    pub const PFD_DOUBLEBUFFER = 0x00000001;
    pub const PFD_TYPE_RGBA = 0;
    pub const PFD_MAIN_PLANE = 0;

    pub const HGLRC = windows.HANDLE;

    pub const GWLP_USERDATA = -21;

    pub const WNDCLASSEXW = extern struct {
        cbSize: windows.UINT,
        style: windows.UINT,
        lpfnWndProc: WNDPROC,
        cbClsExtra: i32,
        cbWndExtra: i32,
        hInstance: windows.HINSTANCE,
        hIcon: ?windows.HICON,
        hCursor: ?windows.HCURSOR,
        hbrBackground: ?windows.HBRUSH,
        lpszMenuName: ?windows.LPCWSTR,
        lpszClassName: windows.LPCWSTR,
        hIconSm: ?windows.HICON,
    };

    pub const MSG = extern struct {
        hwnd: ?windows.HWND,
        message: windows.UINT,
        wParam: windows.WPARAM,
        lParam: windows.LPARAM,
        time: windows.DWORD,
        pt: POINT,
        lPrivate: windows.DWORD,
    };

    pub const POINT = extern struct {
        x: i32,
        y: i32,
    };

    pub const WNDPROC = *const fn (
        hwnd: windows.HWND,
        uMsg: windows.UINT,
        wParam: windows.WPARAM,
        lParam: windows.LPARAM,
    ) callconv(windows.WINAPI) windows.LRESULT;

    pub const CS_HREDRAW = 0x0002;
    pub const CS_VREDRAW = 0x0001;
    pub const IDC_ARROW: windows.LPCWSTR = @ptrFromInt(32512);
    pub const WS_OVERLAPPEDWINDOW = 0x00CF0000;
    pub const WS_VISIBLE = 0x10000000;
    pub const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000));
    pub const SW_SHOW = 5;
    pub const WM_DESTROY = 0x0002;
    pub const WM_PAINT = 0x000F;
    pub const WM_SIZE = 0x0005;
    pub const WM_CLOSE = 0x0010;
    pub const WM_KEYDOWN = 0x0100;
    pub const WM_KEYUP = 0x0101;
    pub const WM_CHAR = 0x0102;
    pub const WM_NULL = 0x0000;
};
