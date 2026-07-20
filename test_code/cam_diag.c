/*
 * cam_diag.c - Camera Interface Diagnostic for Zybo Z7-20
 * Tests all V4L2 capabilities to find working configuration
 *
 * Build: gcc -o cam_diag cam_diag.c -Wall
 * Run:   sudo ./cam_diag
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <linux/videodev2.h>
#include <linux/media.h>
#include <linux/v4l2-subdev.h>

#define CAMERA_DEV "/dev/video0"

static const char *memtype_name(int t) {
    switch(t) {
        case V4L2_MEMORY_MMAP:    return "MMAP";
        case V4L2_MEMORY_USERPTR: return "USERPTR";
        case V4L2_MEMORY_DMABUF:  return "DMABUF";
        case V4L2_MEMORY_OVERLAY: return "OVERLAY";
        default: return "UNKNOWN";
    }
}

static const char *bufname(int t) {
    switch(t) {
        case V4L2_BUF_TYPE_VIDEO_CAPTURE:        return "CAPTURE";
        case V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE: return "CAPTURE_MPLANE";
        default: return "OTHER";
    }
}

static void print_pixfmt(int f) {
    switch(f) {
        case V4L2_PIX_FMT_YUYV:    printf("YUYV"); break;
        case V4L2_PIX_FMT_NV12:    printf("NV12"); break;
        case V4L2_PIX_FMT_GREY:    printf("GREY"); break;
        case V4L2_PIX_FMT_RGB565:  printf("RGB565"); break;
        case V4L2_PIX_FMT_MJPEG:   printf("MJPEG"); break;
        case V4L2_PIX_FMT_SRGGB8:  printf("SRGGB8"); break;
        case V4L2_PIX_FMT_SBGGR8:  printf("SBGGR8"); break;
        case V4L2_PIX_FMT_SGBRG8:  printf("SGBRG8"); break;
        case V4L2_PIX_FMT_SGRBG8:  printf("SGRBG8"); break;
        case V4L2_PIX_FMT_Z16:     printf("Z16"); break;
        default: printf("0x%08X", f); break;
    }
}

int main(void)
{
    printf("==============================================\n");
    printf("  Camera Diagnostic (xilinx-vipp)\n");
    printf("==============================================\n\n");

    int fd = open(CAMERA_DEV, O_RDWR | O_NONBLOCK);
    if (fd < 0) { perror("open"); return 1; }

    /* 1. Basic Info */
    struct v4l2_capability cap;
    ioctl(fd, VIDIOC_QUERYCAP, &cap);
    printf("[INFO] Driver:     %s\n", cap.driver);
    printf("[INFO] Card:       %s\n", cap.card);
    printf("[INFO] Bus:        %s\n", cap.bus_info);
    printf("[INFO] Version:    %d.%d.%d\n",
           (cap.version >> 16) & 0xFF,
           (cap.version >> 8) & 0xFF,
           cap.version & 0xFF);
    printf("[INFO] Capabilities: 0x%08X\n", cap.capabilities);
    printf("[INFO] Device Caps:  0x%08X\n", cap.device_caps);

    printf("\n[CAPS] Decode:\n");
    if (cap.device_caps & V4L2_CAP_VIDEO_CAPTURE)
        printf("  + Video Capture (single-planar)\n");
    if (cap.device_caps & V4L2_CAP_VIDEO_CAPTURE_MPLANE)
        printf("  + Video Capture (multi-planar)\n");
    if (cap.device_caps & V4L2_CAP_STREAMING)
        printf("  + Streaming\n");
    if (cap.device_caps & V4L2_CAP_EXT_PIX_FORMAT)
        printf("  + Extended Pix Format\n");
    if (cap.device_caps & V4L2_CAP_READWRITE)
        printf("  + Read/Write\n");
    if (cap.capabilities & V4L2_CAP_DEVICE_CAPS)
        printf("  + Device Capabilities\n");

    /* 2. Current format */
    printf("\n[FMT] Query current format:\n");

    struct v4l2_format fmt_sp;
    memset(&fmt_sp, 0, sizeof(fmt_sp));
    fmt_sp.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    if (ioctl(fd, VIDIOC_G_FMT, &fmt_sp) == 0) {
        printf("  Single-planar: %dx%d, fmt=", fmt_sp.fmt.pix.width, fmt_sp.fmt.pix.height);
        print_pixfmt(fmt_sp.fmt.pix.pixelformat);
        printf("\n");
    } else {
        printf("  Single-planar: G_FMT failed (%s)\n", strerror(errno));
    }

    struct v4l2_format fmt_mp;
    memset(&fmt_mp, 0, sizeof(fmt_mp));
    fmt_mp.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    if (ioctl(fd, VIDIOC_G_FMT, &fmt_mp) == 0) {
        printf("  Multi-planar:  %dx%d, fmt=", fmt_mp.fmt.pix_mp.width, fmt_mp.fmt.pix_mp.height);
        print_pixfmt(fmt_mp.fmt.pix_mp.pixelformat);
        printf(", planes=%d\n", fmt_mp.fmt.pix_mp.num_planes);
    } else {
        printf("  Multi-planar:  G_FMT failed (%s)\n", strerror(errno));
    }

    /* 3. Enumerate supported formats */
    printf("\n[FMT] Supported pixel formats:\n");
    int i;
    for (i = 0; i < 100; i++) {
        struct v4l2_fmtdesc desc;
        memset(&desc, 0, sizeof(desc));
        desc.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
        desc.index = i;
        if (ioctl(fd, VIDIOC_ENUM_FMT, &desc) < 0) break;
        printf("  [MP:%d] ", i);
        print_pixfmt(desc.pixelformat);
        printf(" - %s\n", desc.description);
    }
    for (i = 0; i < 100; i++) {
        struct v4l2_fmtdesc desc;
        memset(&desc, 0, sizeof(desc));
        desc.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        desc.index = i;
        if (ioctl(fd, VIDIOC_ENUM_FMT, &desc) < 0) break;
        printf("  [SP:%d] ", i);
        print_pixfmt(desc.pixelformat);
        printf(" - %s\n", desc.description);
    }

    /* 4. Frame sizes for YUYV */
    printf("\n[FMT] Supported frame sizes (YUYV):\n");
    struct v4l2_frmsizeenum fs;
    memset(&fs, 0, sizeof(fs));
    fs.pixel_format = V4L2_PIX_FMT_YUYV;
    for (i = 0; i < 50; i++) {
        fs.index = i;
        if (ioctl(fd, VIDIOC_ENUM_FRAMESIZES, &fs) < 0) break;
        if (fs.type == V4L2_FRMSIZE_TYPE_DISCRETE)
            printf("  %dx%d\n", fs.discrete.width, fs.discrete.height);
        else if (fs.type == V4L2_FRMSIZE_TYPE_STEPWISE)
            printf("  %dx%d - %dx%d (step %dx%d)\n",
                   fs.stepwise.min_width, fs.stepwise.min_height,
                   fs.stepwise.max_width, fs.stepwise.max_height,
                   fs.stepwise.step_width, fs.stepwise.step_height);
    }

    /* 5. REQBUFS tests */
    printf("\n[BUF] REQBUFS tests:\n");

    int types[] = {
        V4L2_BUF_TYPE_VIDEO_CAPTURE,
        V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE,
        0
    };
    int mems[] = {
        V4L2_MEMORY_MMAP,
        V4L2_MEMORY_USERPTR,
        V4L2_MEMORY_DMABUF,
        0
    };

    int ti, mi, cnt;
    for (ti = 0; types[ti]; ti++) {
        for (mi = 0; mems[mi]; mi++) {
            for (cnt = 1; cnt <= 4; cnt++) {
                struct v4l2_requestbuffers req;
                memset(&req, 0, sizeof(req));
                req.count  = cnt;
                req.type   = types[ti];
                req.memory = mems[mi];

                int ret = ioctl(fd, VIDIOC_REQBUFS, &req);
                printf("  REQBUFS type=%-25s mem=%-8s cnt=%d => %s",
                       bufname(types[ti]), memtype_name(mems[mi]), cnt,
                       ret == 0 ? "OK" : strerror(errno));
                if (ret == 0) {
                    printf(" (got %d)\n", req.count);
                    req.count = 0;
                    ioctl(fd, VIDIOC_REQBUFS, &req);
                } else {
                    printf("\n");
                }
            }
        }
    }

    /* 6. QUERYBUF without REQBUFS */
    printf("\n[BUF] QUERYBUF without REQBUFS (index 0):\n");
    for (ti = 0; types[ti]; ti++) {
        struct v4l2_buffer buf;
        memset(&buf, 0, sizeof(buf));
        buf.type   = types[ti];
        buf.index  = 0;
        buf.memory = V4L2_MEMORY_MMAP;

        int ret = ioctl(fd, VIDIOC_QUERYBUF, &buf);
        printf("  QUERYBUF type=%-25s => %s",
               bufname(types[ti]),
               ret == 0 ? "OK" : strerror(errno));
        if (ret == 0)
            printf(" (len=%d, offset=0x%X)", buf.length, buf.m.offset);
        printf("\n");
    }

    /* 7. Controls */
    printf("\n[CTRL] Available controls:\n");
    struct v4l2_queryctrl qc;
    int id;
    for (id = V4L2_CID_BASE; id < V4L2_CID_LASTP1; id++) {
        qc.id = id;
        if (ioctl(fd, VIDIOC_QUERYCTRL, &qc) == 0) {
            printf("  %s (0x%08X): min=%d max=%d step=%d default=%d\n",
                   qc.name, qc.id, qc.minimum, qc.maximum, qc.step, qc.default_value);
        }
    }
    for (id = V4L2_CID_USER_BASE; id < V4L2_CID_USER_BASE + 0x1000; id++) {
        qc.id = id;
        if (ioctl(fd, VIDIOC_QUERYCTRL, &qc) == 0) {
            printf("  %s (0x%08X): min=%d max=%d step=%d default=%d\n",
                   qc.name, qc.id, qc.minimum, qc.maximum, qc.step, qc.default_value);
        }
    }

    /* 8. Subdevs */
    printf("\n[SUBDEV] Check subdevs:\n");
    for (i = 0; i < 10; i++) {
        char path[64];
        snprintf(path, sizeof(path), "/dev/v4l-subdev%d", i);
        int sfd = open(path, O_RDWR);
        if (sfd < 0) break;
        printf("  %s => opened\n", path);
        close(sfd);
    }

    close(fd);
    printf("\n[DONE]\n");
    return 0;
}
