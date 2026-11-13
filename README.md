# 定制版 CEF 5414 说明

基于 CEF 5414（Chromium 109.0.5414.120）。相对官方版本的改动：

| 改动 | 说明 |
|---|---|
| 外部视频源 `cef_external_video_*` | 宿主进程把自己解码的 YUV 4:2:0 帧（YV12 / I420）推给 CEF，页面用 `<video>` 显示，由 Chromium 自己的合成器渲染，所有 CSS 都能用。本文主要介绍这一项 |
| H.265 / HEVC 软解 | ffmpeg 增加了 HEVC 解码器和解析器，并去掉了 Main / Main10 profile 的限制 |
| VS2026 构建 | Chromium 109 原本只支持 VS2017/2019/2022，现在可以用 VS2026（MSVC 14.5x + Windows SDK 10.0.26100）编译 |
| 不带 cef_sandbox | 分发包中没有 `cef_sandbox.lib`。宿主程序需要设置 `CefSettings.no_sandbox = true`（CMake 里设 `USE_SANDBOX=OFF`）。本版本只适合加载自己的可信页面 |

源码改动全部以 patch 的形式放在仓库根目录，由 `create_project.bat` 应用。

---

## 外部视频源

### 原理

```
宿主解码器 ──cef_external_video_push_frame()──▶ libcef（浏览器进程）
                                                  │ 拷贝进共享内存
                                                  ▼
                              video capture service：每路注册成一个虚拟摄像头
                                                  │
                                                  ▼
                 渲染进程：getUserMedia() → MediaStream → <video>
                                                  │
                                                  ▼
                              Chromium 合成器：CSS、动画、滤镜全部生效
```

每一路视频注册成一个虚拟摄像头。页面在 `enumerateDevices()` 里按 label 找到它，用 `getUserMedia()` 打开，再赋给 `video.srcObject`。

### 头文件和链接

- 头文件：`include/cef_external_video.h`，纯 C 接口
- 链接：`libcef.lib`，函数从 `libcef.dll` 导出

### 接口

#### `cef_external_video_create`

```c
cef_external_video_t* cef_external_video_create(const char* device_id,
                                                const char* label,
                                                int max_width,
                                                int max_height,
                                                float max_fps);
```

创建一路视频源，并把它注册成一个虚拟摄像头。

| 参数 | 说明 |
|---|---|
| `device_id` | 唯一 ID（UTF-8），每一路都不能重复 |
| `label` | 页面在 `enumerateDevices()` 中看到的设备名（UTF-8），**前端按它来匹配设备**。页面拿到的 `deviceId` 是按 origin 做过哈希的，不能直接用 |
| `max_width`、`max_height` | 帧尺寸上限，超过的帧会被拒绝；小于它的帧原样显示，不会被放大，也不会多占内存。传 0 表示默认值 8192×8192 |
| `max_fps` | 填这路流的标称帧率，传 0 表示默认值 30。它决定“无信号”的判定时间：超过 `25 / max_fps` 秒（第一帧之前是 `100 / max_fps` 秒）没有新帧，页面上的 track 会变成 muted，并触发 `track.onmute`；新帧一到就恢复。期间画面停在最后一帧 |

返回句柄。参数非法（负数、超过 Chromium 的上限）或者 CEF 还没初始化时返回 `NULL`。

#### `cef_external_video_push_frame`

```c
int cef_external_video_push_frame(cef_external_video_t* source,
                                  const uint8_t* y, int y_stride,
                                  const uint8_t* u, int u_stride,
                                  const uint8_t* v, int v_stride,
                                  int width, int height,
                                  int64_t timestamp_us,
                                  const cef_external_video_color_t* color);
```

推送一帧 8bit YUV 4:2:0 平面数据。

- **Y/U/V 三个平面分别传指针**，所以 YV12（内存顺序 Y、V、U）和 I420（Y、U、V）都能用，只要把指针传对。色度平面的尺寸是 `((width+1)/2) × ((height+1)/2)`。
- 函数返回前数据已经拷贝走，调用方的缓冲区可以马上复用。
- **`timestamp_us`**：PTS，单位微秒，要求单调递增，起点随意。显示时机不看它，新帧到了就上屏。但如果前端设置了 `frameRate` 约束，或者用 MediaRecorder、WebRTC、WebCodecs 处理这条轨道，就会用到它，所以必须传对。注意别把毫秒当成微秒传。
- **`color`**：这一帧的色彩描述，可以逐帧不同，传 `NULL` 表示全部未指定。见下文的“色彩描述”。
- 返回 1 表示已接收，0 表示被拒绝。拒绝的原因可能是参数非法、source 正在销毁，或者与 video capture service 的连接断了；如果是最后一种，destroy 掉再重新 create。
- 只保留最新帧：推得比页面消费得快时，旧帧会被直接丢掉，不会堆积，延迟也不会越来越大。

连续存放的 YV12 缓冲区可以直接用辅助函数：

```c
// buffer：Y 平面（stride 为 y_stride），然后是 V、U 平面（stride 为 y_stride/2），中间没有填充行
int cef_external_video_push_yv12(cef_external_video_t* source, const uint8_t* buffer,
                                 int y_stride, int width, int height,
                                 int64_t timestamp_us,
                                 const cef_external_video_color_t* color);
```

#### `cef_external_video_destroy`

```c
void cef_external_video_destroy(cef_external_video_t* source);
```

注销这个虚拟摄像头，并释放句柄。调用之后句柄不能再用。

页面这边：会收到 `devicechange` 事件；正在显示这一路的 track 会停止更新（video capture service 会通知采集端停止，预计 track 会变成 `ended`，具体以实测为准）。建议前端同时监听 `devicechange` 和 `track.onended`。

#### 线程和生命周期

- 三个函数都可以在**任意线程**调用。不同的 source 可以在不同线程上并发推帧。
- 只能在 `CefInitialize()` 之后（建议在 `CefBrowserProcessHandler::OnContextInitialized()` 里）创建。
- 退出时的顺序：停掉解码线程 → destroy 所有 source → `CefShutdown()`。
- 不要在同一个 source 上让 push 和 destroy 并发。

### 色彩描述

```c
typedef struct _cef_external_video_color_t {
  int primaries;  // 原色（色域），H.273 ColourPrimaries
  int transfer;   // 传递函数（gamma 曲线），H.273 TransferCharacteristics
  int matrix;     // YUV↔RGB 矩阵，H.273 MatrixCoefficients
  int range;      // 0 未指定（按 limited 处理）/ 1 limited（16~235）/ 2 full（0~255）
} cef_external_video_color_t;
```

- `primaries`、`transfer`、`matrix` 用的是 ITU-T H.273 的编号，和 H.264/H.265 码流里 VUI 的值是同一套。所以：
  - FFmpeg（`AVFrame` 的 `color_primaries`、`color_trc`、`colorspace`、`color_range`）、oneVPL、NVDEC 拿到的值可以直接填；
  - Media Foundation、DXGI、libvpx 用的是各自的编号，需要按名字对照转换。
  - 头文件注释里列出了每个字段的全部取值，以及各种库的对照方法。
- 码流里没写时填 2（未指定），由 CEF 推测：三个字段都未指定时，高度 ≥ 720 按 BT.709，否则按 BT.601；range 未指定时按 limited。
- 最常见的情况：高清视频和大多数摄像头是 **BT.709 + limited**，即 `{1, 1, 1, 1}`。不少监控摄像头输出的是 **full range**（FFmpeg 里显示为 `yuvj420p`）。画面发灰、发白，或者暗部全黑，多半是 range 填错了。
- 填的值必须和像素实际的编码方式一致。不要为了“保险”一律标成 BT.2020。

---

## 宿主进程：多路使用的最简例子

```cpp
#include <string>
#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_external_video.h"

constexpr int kStreamCount = 4;
cef_external_video_t* g_sources[kStreamCount] = {};

class App : public CefApp, public CefBrowserProcessHandler {
 public:
  CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override {
    return this;
  }

  // 允许页面用 getUserMedia() 打开虚拟摄像头（见下文“权限”）。
  void OnBeforeCommandLineProcessing(
      const CefString& process_type,
      CefRefPtr<CefCommandLine> command_line) override {
    if (process_type.empty())
      command_line->AppendSwitch("enable-media-stream");
  }

  void OnContextInitialized() override {
    // 每一路创建一个视频源。label 就是前端用来查找设备的名字。
    for (int i = 0; i < kStreamCount; ++i) {
      const std::string name = "cam" + std::to_string(i + 1);
      g_sources[i] = cef_external_video_create(name.c_str(), name.c_str(),
                                               0, 0, 25);  // 默认最大尺寸，25fps
    }

    CefWindowInfo window_info;
    window_info.SetAsPopup(nullptr, "app");
    CefBrowserHost::CreateBrowser(window_info, nullptr,
                                  "file:///C:/app/index.html",
                                  CefBrowserSettings(), nullptr, nullptr);
  }

 private:
  IMPLEMENT_REFCOUNTING(App);
};

// 解码线程里每解出一帧就调用一次。可以在任意线程调用，多路之间可以并发。
void OnFrameDecoded(int stream,
                    const uint8_t* y, int y_stride,
                    const uint8_t* u, int u_stride,
                    const uint8_t* v, int v_stride,
                    int width, int height, int64_t pts_us) {
  const cef_external_video_color_t color = {
      CEF_EXTERNAL_VIDEO_PRIMARIES_BT709, CEF_EXTERNAL_VIDEO_TRANSFER_BT709,
      CEF_EXTERNAL_VIDEO_MATRIX_BT709, CEF_EXTERNAL_VIDEO_RANGE_LIMITED};
  cef_external_video_push_frame(g_sources[stream], y, y_stride, u, u_stride,
                                v, v_stride, width, height, pts_us, &color);
}

int APIENTRY wWinMain(HINSTANCE instance, HINSTANCE, LPTSTR, int) {
  CefMainArgs main_args(instance);
  CefRefPtr<App> app(new App);
  int exit_code = CefExecuteProcess(main_args, app, nullptr);
  if (exit_code >= 0)
    return exit_code;

  CefSettings settings;
  settings.no_sandbox = true;  // 本版本不带 cef_sandbox
  CefInitialize(main_args, settings, app, nullptr);

  StartDecoders();       // 你的解码线程，内部调用 OnFrameDecoded()

  CefRunMessageLoop();

  StopDecoders();        // 1. 先停止推帧
  for (cef_external_video_t* source : g_sources)
    cef_external_video_destroy(source);  // 2. 再销毁视频源
  CefShutdown();         // 3. 最后关闭 CEF
  return 0;
}
```

解码器输出的是连续存放的 YV12 缓冲区时，`OnFrameDecoded` 里改成一行：

```cpp
cef_external_video_push_yv12(g_sources[stream], buffer, width, width, height, pts_us, &color);
```

---

## 前端：多路使用的最简例子

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  .grid  { display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; }
  video  { width: 100%; aspect-ratio: 16 / 9; object-fit: contain;
           background: #000; border-radius: 8px; }
</style>
</head>
<body>
<div class="grid">
  <video data-label="cam1" muted autoplay playsinline></video>
  <video data-label="cam2" muted autoplay playsinline></video>
  <video data-label="cam3" muted autoplay playsinline></video>
  <video data-label="cam4" muted autoplay playsinline></video>
</div>
<script>
const streams = new Map();  // label -> MediaStream，同一路只打开一次

async function openStream(label) {
  if (streams.has(label)) return streams.get(label);
  const devices = await navigator.mediaDevices.enumerateDevices();
  const device = devices.find(d => d.kind === 'videoinput' && d.label === label);
  if (!device) return null;  // 设备还没注册，等 devicechange 再试
  const stream = await navigator.mediaDevices.getUserMedia({
    video: { deviceId: { exact: device.deviceId } }, audio: false });
  streams.set(label, stream);
  stream.getVideoTracks()[0].onended = () => streams.delete(label);  // 宿主 destroy 了这一路
  return stream;
}

async function attachAll() {
  for (const video of document.querySelectorAll('video[data-label]')) {
    if (video.srcObject && video.srcObject.active) continue;
    const stream = await openStream(video.dataset.label);
    if (stream) video.srcObject = stream;  // 同一路显示在多个 <video> 里时共用这个 stream
  }
}

// 宿主新增或删除了某一路时会触发
navigator.mediaDevices.addEventListener('devicechange', attachAll);
attachAll();
</script>
</body>
</html>
```

要点：
- 页面必须是安全上下文：`file://` 可以；自定义 scheme 要注册成 secure。
- 同一路要显示在多个 `<video>` 里时，共用同一个 MediaStream，或者用 `track.clone()`，不要重复调用 `getUserMedia`。
- 真实分辨率用 `video.videoWidth` / `video.videoHeight` 取。
- “无信号”可以用 `track.onmute` / `track.onunmute` 判断，超时时间由 `max_fps` 决定，见上文。

---

## 权限

`getUserMedia()` 需要摄像头权限。CEF 默认会拒绝，有两种放行方式：

| 方式 | 说明 |
|---|---|
| 命令行开关 `--enable-media-stream` | 浏览器进程收到任何媒体权限请求都直接同意，不再询问。范围包括摄像头、麦克风、桌面录屏和系统声音录制，**对所有页面一律放行**。写起来最简单，适合只加载自己本地页面的客户端 |
| 实现 `CefPermissionHandler::OnRequestMediaAccessPermission()` | 可以按页面来源和权限类型逐个判断，比如只给自己的页面放行“摄像头”（`CEF_MEDIA_PERMISSION_DEVICE_VIDEO_CAPTURE`）。页面一旦可能加载外部内容，就应该用这种方式 |

注意：页面通过 `getUserMedia` 看到的是机器上的**所有**摄像头，包括真实的物理摄像头。所以前端一定要按 label 选设备，不要用默认设备。

---

## 性能参考

在 Ryzen 9 5950X（32 线程）上，用 cefsimple 演示程序测试：同时推 2 路 3840×2100@60fps，4 个 `<video>` 同时显示并带 CSS 动画，各路都稳定 60fps 上屏。整体 CPU 占用约 17%（主要在渲染进程），GPU 约 24%。

每帧的数据路径是：调用方内存 → 内部帧缓冲 → 共享内存 → 渲染进程上传 GPU，其中 CPU 拷贝 2 次。

## 限制

- 只支持 8bit 4:2:0（YV12/I420）、SDR。没有 HDR，也不支持 10bit。
- 这是实时流：最新一帧立即上屏，没有缓冲，也没有音画同步。音频需要另外处理。
