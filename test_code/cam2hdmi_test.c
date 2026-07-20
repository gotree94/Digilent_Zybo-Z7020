/*
 * cam2hdmi_test.c - Camera (MIPI CSI-2) to HDMI (Framebuffer) Test
 * For Zybo Z7-20 + Raspberry Pi Camera Rev 1.3
 *
 * Uses Multiplanar V4L2 API (xilinx-vipp driver)
 *
 * Build: gcc -o cam2hdmi_test cam2hdmi_test.c
 * Run:   sudo ./cam2hdmi_test
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <linux/fb.h>
#include <linux/videodev2.h>

#define CAMERA_DEV  "/dev/video0"
#define FB_DEV      "/dev/fb0"
#define NUM_BUFFERS 4
#define TARGET_W    640
#define TARGET_H    480
#define MAX_PLANES  2

/* ---- Framebuffer info ---- */
struct fb_info {
    int fd, width, height, bpp, stride;
    unsigned char *map;
    size_t map_size;
};

/* ---- V4L2 Multiplanar buffer ---- */
struct cam_buf {
    void *start[MAX_PLANES];
    size_t length[MAX_PLANES];
};

/* ================================================================ */
/*  Framebuffer                                                      */
/* ================================================================ */

int fb_open(struct fb_info *fb)
{
    struct fb_var_screeninfo vinfo;
    struct fb_fix_screeninfo finfo;

    fb->fd = open(FB_DEV, O_RDWR);
    if (fb->fd < 0) { perror("fb open"); return -1; }
    if (ioctl(fb->fd, FBIOGET_VSCREENINFO, &vinfo) < 0) { perror("fb var"); close(fb->fd); return -1; }
    if (ioctl(fb->fd, FBIOGET_FSCREENINFO, &finfo) < 0) { perror("fb fix"); close(fb->fd); return -1; }

    fb->width  = vinfo.xres;
    fb->height = vinfo.yres;
    fb->bpp    = vinfo.bits_per_pixel;
    fb->stride = finfo.line_length;
    fb->map_size = finfo.smem_len;
    fb->map = mmap(NULL, fb->map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fb->fd, 0);
    if (fb->map == MAP_FAILED) { perror("fb mmap"); close(fb->fd); return -1; }

    printf("  [FB]  %dx%d, %dbpp, stride=%d, size=%zu\n",
           fb->width, fb->height, fb->bpp, fb->stride, fb->map_size);
    return 0;
}

/* ================================================================ */
/*  Camera (Multiplanar V4L2)                                        */
/* ================================================================ */

static int try_format(int fd, int width, int height, int pixfmt,
                      int *out_w, int *out_h, int *out_fmt)
{
    struct v4l2_format fmt;
    memset(&fmt, 0, sizeof(fmt));
    fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    fmt.fmt.pix_mp.width       = width;
    fmt.fmt.pix_mp.height      = height;
    fmt.fmt.pix_mp.pixelformat = pixfmt;
    fmt.fmt.pix_mp.field       = V4L2_FIELD_NONE;
    fmt.fmt.pix_mp.num_planes  = 1;

    if (ioctl(fd, VIDIOC_S_FMT, &fmt) == 0) {
        *out_w = fmt.fmt.pix_mp.width;
        *out_h = fmt.fmt.pix_mp.height;
        *out_fmt = fmt.fmt.pix_mp.pixelformat;
        return 0;
    }
    return -1;
}

int cam_open(struct cam_buf buffers[], int *nbufs,
             int *width, int *height, int *pixfmt)
{
    int fd = open(CAMERA_DEV, O_RDWR | O_NONBLOCK);
    if (fd < 0) { perror("cam open"); return -1; }

    /* Query capabilities */
    struct v4l2_capability cap;
    if (ioctl(fd, VIDIOC_QUERYCAP, &cap) < 0) {
        perror("VIDIOC_QUERYCAP");
        close(fd); return -1;
    }
    printf("  [CAM] driver: %s, card: %s\n", cap.driver, cap.card);
    printf("  [CAM] device_caps: 0x%08X\n", cap.device_caps);

    /* Verify multiplanar capture */
    if (!(cap.device_caps & V4L2_CAP_VIDEO_CAPTURE_MPLANE)) {
        printf("  [WARN] Device does not report Multiplanar Capture, trying anyway...\n");
    }

    /* Try preferred formats */
    int try_fmts[] = {
        V4L2_PIX_FMT_YUYV,
        V4L2_PIX_FMT_NV12,
        V4L2_PIX_FMT_GREY,
        V4L2_PIX_FMT_SRGGB8,
        V4L2_PIX_FMT_SBGGR8,
        V4L2_PIX_FMT_RGB565,
        0
    };

    int found = 0;
    for (int i = 0; try_fmts[i]; i++) {
        if (try_format(fd, TARGET_W, TARGET_H, try_fmts[i], width, height, pixfmt) == 0) {
            found = 1;
            break;
        }
    }

    if (!found) {
        printf("  [FAIL] Could not negotiate any pixel format\n");
        close(fd); return -1;
    }

    /* Print format name */
    const char *fn = "unknown";
    switch (*pixfmt) {
        case V4L2_PIX_FMT_YUYV:   fn = "YUYV"; break;
        case V4L2_PIX_FMT_NV12:   fn = "NV12"; break;
        case V4L2_PIX_FMT_GREY:   fn = "GREY"; break;
        case V4L2_PIX_FMT_RGB565: fn = "RGB565"; break;
        case V4L2_PIX_FMT_SRGGB8: fn = "SRGGB8 (Bayer RAW)"; break;
        case V4L2_PIX_FMT_SBGGR8: fn = "SBGGR8 (Bayer RAW)"; break;
    }
    printf("  [CAM] format: %s (%dx%d)\n", fn, *width, *height);

    /* Request multiplanar buffers */
    struct v4l2_requestbuffers req;
    memset(&req, 0, sizeof(req));
    req.count  = NUM_BUFFERS;
    req.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    req.memory = V4L2_MEMORY_MMAP;

    if (ioctl(fd, VIDIOC_REQBUFS, &req) < 0) {
        perror("VIDIOC_REQBUFS (multiplanar)");
        printf("  [HINT] Device may not support MMAP multiplanar. Trying userptr...\n");

        /* Try userptr */
        memset(&req, 0, sizeof(req));
        req.count  = NUM_BUFFERS;
        req.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
        req.memory = V4L2_MEMORY_USERPTR;
        if (ioctl(fd, VIDIOC_REQBUFS, &req) < 0) {
            perror("VIDIOC_REQBUFS (userptr)");
            close(fd); return -1;
        }
        printf("  [CAM] Using USERPTR mode\n");
    }

    *nbufs = req.count;
    printf("  [CAM] %d buffers allocated\n", *nbufs);

    /* mmap multiplanar buffers */
    for (int i = 0; i < *nbufs; i++) {
        struct v4l2_buffer vbuf;
        struct v4l2_plane planes[MAX_PLANES];
        memset(&vbuf, 0, sizeof(vbuf));
        memset(planes, 0, sizeof(planes));
        vbuf.type     = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
        vbuf.memory   = V4L2_MEMORY_MMAP;
        vbuf.index    = i;
        vbuf.m.planes = planes;
        vbuf.length   = MAX_PLANES;

        if (ioctl(fd, VIDIOC_QUERYBUF, &vbuf) < 0) {
            perror("VIDIOC_QUERYBUF");
            close(fd); return -1;
        }

        for (int p = 0; p < vbuf.length; p++) {
            if (vbuf.m.planes[p].length == 0) break;
            buffers[i].length[p] = vbuf.m.planes[p].length;
            buffers[i].start[p] = mmap(NULL, vbuf.m.planes[p].length,
                                        PROT_READ | PROT_WRITE, MAP_SHARED,
                                        fd, vbuf.m.planes[p].m.mem_offset);
            if (buffers[i].start[p] == MAP_FAILED) {
                perror("cam mmap plane");
                close(fd); return -1;
            }
        }

        if (ioctl(fd, VIDIOC_QBUF, &vbuf) < 0) {
            perror("VIDIOC_QBUF");
            close(fd); return -1;
        }
    }

    /* Start streaming */
    int type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    if (ioctl(fd, VIDIOC_STREAMON, &type) < 0) {
        perror("VIDIOC_STREAMON");
        close(fd); return -1;
    }

    printf("  [CAM] streaming started\n");
    return fd;
}

/* ================================================================ */
/*  Format conversion                                                */
/* ================================================================ */

static inline unsigned char clamp8(int v)
{
    return (v < 0) ? 0 : (v > 255) ? 255 : (unsigned char)v;
}

/* YUYV -> RGB565 */
static void yuyv_to_rgb565(const unsigned char *src, int w, int h,
                            unsigned char *dst, int fb_stride)
{
    for (int row = 0; row < h; row++) {
        unsigned char *d = dst + row * fb_stride;
        const unsigned char *s = src + row * w * 2;

        for (int col = 0; col < w; col += 2) {
            int y0 = s[0], u = s[1], y1 = s[2], v = s[3]; s += 4;
            int c0 = y0 - 16, c1 = y1 - 16, d1 = u - 128, e = v - 128;

            unsigned short p0 = ((clamp8((298*c0+409*e+128)>>8) >> 3) << 11) |
                                ((clamp8((298*c0-100*d1-208*e+128)>>8) >> 2) << 5) |
                                (clamp8((298*c0+516*d1+128)>>8) >> 3);
            unsigned short p1 = ((clamp8((298*c1+409*e+128)>>8) >> 3) << 11) |
                                ((clamp8((298*c1-100*d1-208*e+128)>>8) >> 2) << 5) |
                                (clamp8((298*c1+516*d1+128)>>8) >> 3);

            d[0] = p0 & 0xFF; d[1] = (p0 >> 8) & 0xFF;
            d[2] = p1 & 0xFF; d[3] = (p1 >> 8) & 0xFF;
            d += 4;
        }
    }
}

/* NV12 -> RGB565 */
static void nv12_to_rgb565(const unsigned char *src, int w, int h,
                           unsigned char *dst, int fb_stride)
{
    const unsigned char *y_plane = src;
    const unsigned char *uv_plane = src + w * h;

    for (int row = 0; row < h; row++) {
        unsigned char *d = dst + row * fb_stride;
        for (int col = 0; col < w; col += 2) {
            int y0 = y_plane[row * w + col];
            int y1 = y_plane[row * w + col + 1];
            int uv_idx = (row / 2) * w + col;
            int u = uv_plane[uv_idx];
            int v = uv_plane[uv_idx + 1];

            int c0 = y0 - 16, c1 = y1 - 16, d1 = u - 128, e = v - 128;

            unsigned short p0 = ((clamp8((298*c0+409*e+128)>>8) >> 3) << 11) |
                                ((clamp8((298*c0-100*d1-208*e+128)>>8) >> 2) << 5) |
                                (clamp8((298*c0+516*d1+128)>>8) >> 3);
            unsigned short p1 = ((clamp8((298*c1+409*e+128)>>8) >> 3) << 11) |
                                ((clamp8((298*c1-100*d1-208*e+128)>>8) >> 2) << 5) |
                                (clamp8((298*c1+516*d1+128)>>8) >> 3);

            d[0] = p0 & 0xFF; d[1] = (p0 >> 8) & 0xFF;
            d[2] = p1 & 0xFF; d[3] = (p1 >> 8) & 0xFF;
            d += 4;
        }
    }
}

/* RAW8 Bayer (RGGB/BGGR) -> RGB565 (simple nearest-neighbor demosaic) */
static void bayer_to_rgb565(const unsigned char *src, int w, int h,
                            unsigned char *dst, int fb_stride)
{
    for (int row = 0; row < h; row++) {
        unsigned char *d = dst + row * fb_stride;
        for (int col = 0; col < w; col++) {
            int idx = row * w + col;
            int r, g, b;

            /* Checkerboard pattern for RGGB */
            int is_gr = (row % 2 == 0 && col % 2 == 1) || (row % 2 == 1 && col % 2 == 0);

            if (row % 2 == 0 && col % 2 == 0) {
                r = src[idx]; g = (src[idx+1] + src[idx+w]) / 2; b = src[idx+w+1];
            } else if (row % 2 == 0 && col % 2 == 1) {
                g = src[idx]; r = (src[idx-1] + src[idx+1]) / 2; b = src[idx+w];
                if (col == 0) r = src[idx+1];
            } else if (row % 2 == 1 && col % 2 == 0) {
                g = src[idx]; b = (src[idx-w] + src[idx+w]) / 2; r = src[idx+1];
            } else {
                b = src[idx]; g = (src[idx-1] + src[idx+1]) / 2; r = src[idx-w];
            }

            unsigned short p = ((clamp8(r) >> 3) << 11) |
                               ((clamp8(g) >> 2) << 5) |
                               (clamp8(b) >> 3);
            d[col * 2]     = p & 0xFF;
            d[col * 2 + 1] = (p >> 8) & 0xFF;
        }
    }
}

/* ================================================================ */
/*  Framebuffer write (centered)                                     */
/* ================================================================ */

void fb_write_centered(struct fb_info *fb, const unsigned char *src_rgb565,
                       int sw, int sh)
{
    memset(fb->map, 0, fb->map_size);

    int xoff = (fb->width  - sw) / 2;
    int yoff = (fb->height - sh) / 2;
    if (xoff < 0) xoff = 0;
    if (yoff < 0) yoff = 0;

    int bpp = fb->bpp / 8;
    int copy_w = sw * bpp;
    if (copy_w > fb->stride) copy_w = fb->stride;

    for (int row = 0; row < sh && (yoff + row) < fb->height; row++) {
        unsigned char *dst = fb->map + (yoff + row) * fb->stride + xoff * bpp;
        const unsigned char *s = src_rgb565 + row * sw * bpp;
        memcpy(dst, s, copy_w);
    }
}

/* ================================================================ */
/*  Main                                                             */
/* ================================================================ */

int main(int argc, char *argv[])
{
    printf("==============================================\n");
    printf("  Camera to HDMI Test (Zybo Z7-20)\n");
    printf("  Multiplanar V4L2 + Framebuffer\n");
    printf("==============================================\n\n");

    /* Step 1: Framebuffer */
    struct fb_info fb;
    printf("[STEP 1] Open framebuffer\n");
    if (fb_open(&fb) < 0) {
        printf("  [FATAL] Cannot open framebuffer\n");
        return 1;
    }

    /* Step 2: Camera */
    printf("\n[STEP 2] Open camera\n");
    struct cam_buf cam_bufs[NUM_BUFFERS];
    int nbufs = 0, cam_w = 0, cam_h = 0, pixfmt = 0;
    int cam_fd = cam_open(cam_bufs, &nbufs, &cam_w, &cam_h, &pixfmt);
    if (cam_fd < 0) {
        printf("\n  [FATAL] Cannot open camera.\n");
        printf("  Check:\n");
        printf("    1. Raspberry Pi Camera connected to Pcam port?\n");
        printf("    2. dmesg | grep -i mipi\n");
        printf("    3. v4l2-ctl --device=/dev/video0 --info\n");
        munmap(fb.map, fb.map_size);
        close(fb.fd);
        return 1;
    }

    /* Step 3: Capture loop */
    printf("\n[STEP 3] Capture -> Display (Ctrl+C to stop)\n");
    printf("  Camera: %dx%d -> FB: %dx%d\n\n", cam_w, cam_h, fb.width, fb.height);

    unsigned char *cvt = malloc(cam_w * (cam_h + 1) * 2);
    if (!cvt) { printf("  [FATAL] malloc\n"); goto cleanup; }

    int fc = 0;
    struct timeval t0, t1;
    gettimeofday(&t0, NULL);

    while (1) {
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(cam_fd, &fds);
        struct timeval tv = { .tv_sec = 2, .tv_usec = 0 };

        int ret = select(cam_fd + 1, &fds, NULL, NULL, &tv);
        if (ret < 0) { if (errno == EINTR) continue; perror("select"); break; }
        if (ret == 0) { printf("  [WARN] timeout\n"); continue; }

        /* Dequeue multiplanar buffer */
        struct v4l2_buffer vbuf;
        struct v4l2_plane planes[MAX_PLANES];
        memset(&vbuf, 0, sizeof(vbuf));
        memset(planes, 0, sizeof(planes));
        vbuf.type     = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
        vbuf.memory   = V4L2_MEMORY_MMAP;
        vbuf.m.planes = planes;
        vbuf.length   = MAX_PLANES;

        if (ioctl(cam_fd, VIDIOC_DQBUF, &vbuf) < 0) {
            if (errno == EAGAIN) continue;
            perror("VIDIOC_DQBUF");
            break;
        }

        fc++;

        /* Convert and display */
        const unsigned char *frame = cam_bufs[vbuf.index].start[0];
        int frame_len = vbuf.m.planes[0].bytesused;

        if (pixfmt == V4L2_PIX_FMT_YUYV) {
            yuyv_to_rgb565(frame, cam_w, cam_h, cvt, fb.stride);
            fb_write_centered(&fb, cvt, cam_w, cam_h);
        } else if (pixfmt == V4L2_PIX_FMT_NV12) {
            nv12_to_rgb565(frame, cam_w, cam_h, cvt, fb.stride);
            fb_write_centered(&fb, cvt, cam_w, cam_h);
        } else if (pixfmt == V4L2_PIX_FMT_SRGGB8 || pixfmt == V4L2_PIX_FMT_SBGGR8) {
            bayer_to_rgb565(frame, cam_w, cam_h, cvt, fb.stride);
            fb_write_centered(&fb, cvt, cam_w, cam_h);
        } else if (pixfmt == V4L2_PIX_FMT_GREY) {
            /* GREY -> RGB565 */
            for (int r = 0; r < cam_h; r++) {
                unsigned short *d = (unsigned short *)(cvt + r * cam_w * 2);
                for (int c = 0; c < cam_w; c++) {
                    unsigned char g = frame[r * cam_w + c];
                    d[c] = ((g >> 3) << 11) | ((g >> 2) << 5) | (g >> 3);
                }
            }
            fb_write_centered(&fb, cvt, cam_w, cam_h);
        } else {
            /* Unknown: raw copy */
            fb_write_centered(&fb, frame, cam_w, cam_h);
        }

        /* Re-queue */
        if (ioctl(cam_fd, VIDIOC_QBUF, &vbuf) < 0) {
            perror("VIDIOC_QBUF");
            break;
        }

        /* FPS */
        if (fc % 30 == 0) {
            gettimeofday(&t1, NULL);
            double el = (t1.tv_sec - t0.tv_sec) + (t1.tv_usec - t0.tv_usec) / 1e6;
            printf("\r  [FRAME %d] %.1f FPS  (bytesused=%d)   ",
                   fc, fc / el, frame_len);
            fflush(stdout);
        }
    }

    printf("\n\n  Total: %d frames captured\n", fc);
    free(cvt);

cleanup:;
    int type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    ioctl(cam_fd, VIDIOC_STREAMOFF, &type);

    for (int i = 0; i < nbufs; i++)
        for (int p = 0; p < MAX_PLANES; p++)
            if (cam_bufs[i].start[p])
                munmap(cam_bufs[i].start[p], cam_bufs[i].length[p]);
    close(cam_fd);

    munmap(fb.map, fb.map_size);
    close(fb.fd);
    printf("  [DONE]\n");
    return 0;
}
