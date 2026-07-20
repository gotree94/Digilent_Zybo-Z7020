/*
 * hw_test.c - Zybo Z7-20 Hardware Test Program (UIO version)
 *
 * Compile: gcc -o hw_test hw_test.c
 * Run:     ./hw_test
 *
 * PL GPIO access via UIO (uio_pdrv_genirq driver).
 *
 * UIO mapping (verified from system.xsa):
 *   uio0 -> axi_gpio_led    (0x41220000) -> LEDs Ch1 (4 outputs)
 *   uio1 -> axi_gpio_sw_btn (0x41210000) -> Switches Ch1 (4 inputs)
 *                                          -> Buttons   Ch2 (4 inputs, offset 0x08)
 *   uio2 -> axi_gpio_video  (0x41200000) -> HDMI Hotplug Detect (1 bit)
 *   uio3 -> axi_gpio_eth    (0x41230000) -> Ethernet Reset (1 bit)
 *
 * AXI GPIO register map:
 *   Offset 0x00 : GPIO_DATA  (read/write pin values)
 *   Offset 0x04 : GPIO_TRI   (direction: 0=output, 1=input)
 *
 * Tests: LED, Switch, Button, Network, Memory, System Info
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <dirent.h>
#include <sys/mman.h>
#include <time.h>

/* -------------------------------------------------- */
/* PL GPIO via UIO                                    */
/* -------------------------------------------------- */

#define GPIO_DATA_OFFSET 0x00
#define GPIO_TRI_OFFSET  0x04
#define GPIO2_DATA_OFFSET 0x08
#define GPIO2_TRI_OFFSET  0x0C
#define MAP_SIZE          0x10000

/* UIO device addresses (from /sys/class/uio/uioN/maps/map0/addr) */
#define UIO_ADDR_LEDS    0x41220000
#define UIO_ADDR_SWITCH  0x41210000
#define UIO_ADDR_BUTTON  0x41200000

struct uio_gpio {
    int   fd;
    void *map;
};

int uio_open(struct uio_gpio *g, const char *devpath)
{
    g->fd = open(devpath, O_RDWR);
    if (g->fd < 0) return -1;
    g->map = mmap(NULL, MAP_SIZE, PROT_READ | PROT_WRITE,
                  MAP_SHARED, g->fd, 0);
    if (g->map == MAP_FAILED) {
        close(g->fd);
        g->fd = -1;
        return -1;
    }
    return 0;
}

void uio_close(struct uio_gpio *g)
{
    if (g->map && g->map != MAP_FAILED)
        munmap(g->map, MAP_SIZE);
    if (g->fd >= 0)
        close(g->fd);
    g->fd = -1;
    g->map = NULL;
}

static inline unsigned int uio_read32(struct uio_gpio *g, unsigned int offset)
{
    volatile unsigned int *addr =
        (volatile unsigned int *)((char *)g->map + offset);
    return *addr;
}

static inline void uio_write32(struct uio_gpio *g, unsigned int offset,
                                unsigned int val)
{
    volatile unsigned int *addr =
        (volatile unsigned int *)((char *)g->map + offset);
    *addr = val;
}

/* Set pin direction: dir=0 output, dir=1 input (via GPIO_TRI register) */
void uio_set_direction(struct uio_gpio *g, int bit, int dir)
{
    unsigned int tri = uio_read32(g, GPIO_TRI_OFFSET);
    if (dir) /* input */
        tri |= (1u << bit);
    else     /* output */
        tri &= ~(1u << bit);
    uio_write32(g, GPIO_TRI_OFFSET, tri);
}

void uio_set_pin(struct uio_gpio *g, int bit, int val)
{
    unsigned int data = uio_read32(g, GPIO_DATA_OFFSET);
    if (val)
        data |= (1u << bit);
    else
        data &= ~(1u << bit);
    uio_write32(g, GPIO_DATA_OFFSET, data);
}

int uio_get_pin(struct uio_gpio *g, int bit)
{
    return (uio_read32(g, GPIO_DATA_OFFSET) >> bit) & 1;
}

/* -------------------------------------------------- */
/* Test: LED                                          */
/* -------------------------------------------------- */

void test_leds(void)
{
    printf("\n[TEST 1] LED Test (LD4~LD7, 4 LEDs)\n");

    struct uio_gpio led;
    if (uio_open(&led, "/dev/uio0") < 0) {
        printf("  [FAIL] Cannot open /dev/uio0 (LED)\n");
        return;
    }
    printf("  [OK]   LED UIO opened (/dev/uio0, 0x41220000)\n");

    /* All 4 pins as output */
    int i;
    for (i = 0; i < 4; i++)
        uio_set_direction(&led, i, 0);

    /* Individual LED test */
    for (i = 0; i < 4; i++) {
        uio_set_pin(&led, i, 1);
        usleep(300000);

        int val = uio_get_pin(&led, i);
        uio_set_pin(&led, i, 0);

        printf("  [%s] LED%d (LD%d) read=%d\n",
               (val == 1) ? "OK " : "FAIL", i, i + 4, val);
    }

    /* Chase pattern */
    printf("\n[TEST 1b] LED Chase Pattern\n");
    int round;
    for (round = 0; round < 3; round++) {
        for (i = 0; i < 4; i++) {
            uio_set_pin(&led, i, 1);
            usleep(100000);
            uio_set_pin(&led, i, 0);
        }
    }
    printf("  [OK]   Chase pattern completed\n");

    uio_close(&led);
}

/* -------------------------------------------------- */
/* Test: Switch                                       */
/* -------------------------------------------------- */

void test_switches(void)
{
    printf("\n[TEST 2] Switch Test (SW0~SW3)\n");

    struct uio_gpio sw;
    if (uio_open(&sw, "/dev/uio1") < 0) {
        printf("  [FAIL] Cannot open /dev/uio1 (Switch)\n");
        return;
    }
    printf("  [OK]   Switch UIO opened (/dev/uio1, 0x41210000)\n");

    /* All 4 pins as input */
    int i;
    for (i = 0; i < 4; i++)
        uio_set_direction(&sw, i, 1);

    for (i = 0; i < 4; i++) {
        int val = uio_get_pin(&sw, i);
        printf("  [OK]   SW%d = %d\n", i, val);
    }

    /* Polling test */
    printf("\n[TEST 2b] Switch Polling (5s)\n");
    int initial = uio_get_pin(&sw, 0);
    printf("  Initial SW0=%d, toggle within 5s...\n", initial);

    time_t start = time(NULL);
    int changed = 0, current = initial;
    while (time(NULL) - start < 5) {
        current = uio_get_pin(&sw, 0);
        if (current != initial) { changed = 1; break; }
        usleep(50000);
    }

    if (changed)
        printf("  [OK]   SW0 changed: %d -> %d\n", initial, current);
    else
        printf("  [OK]   No change (timeout), SW0=%d\n", initial);

    uio_close(&sw);
}

/* -------------------------------------------------- */
/* Test: Button                                       */
/* -------------------------------------------------- */

void test_buttons(void)
{
    printf("\n[TEST 3] Button Test (Channel 2 of uio1)\n");

    struct uio_gpio btn;
    if (uio_open(&btn, "/dev/uio1") < 0) {
        printf("  [FAIL] Cannot open /dev/uio1 (Button)\n");
        return;
    }
    printf("  [OK]   Button UIO opened (/dev/uio1 Ch2, 0x41210000+0x08)\n");

    /* Channel 2: All pins as input (GPIO2_TRI) */
    int i;
    for (i = 0; i < 4; i++) {
        unsigned int tri = uio_read32(&btn, GPIO2_TRI_OFFSET);
        tri |= (1u << i);
        uio_write32(&btn, GPIO2_TRI_OFFSET, tri);
    }

    for (i = 0; i < 4; i++) {
        int val = (uio_read32(&btn, GPIO2_DATA_OFFSET) >> i) & 1;
        printf("  [OK]   BTN%d = %d\n", i, val);
    }

    uio_close(&btn);
}

/* -------------------------------------------------- */
/* Test: Network                                      */
/* -------------------------------------------------- */

void test_network(void)
{
    printf("\n[TEST 5] Network Test\n");

    int ret = system("ip link show eth0 > /dev/null 2>&1");
    if (ret != 0) {
        printf("  [FAIL] eth0 not found\n");
        return;
    }
    printf("  [OK]   eth0 interface found\n");

    ret = system("udhcpc -i eth0 > /dev/null 2>&1");
    if (ret == 0)
        printf("  [OK]   DHCP completed (udhcpc)\n");
    else
        printf("  [WARN] DHCP failed, trying static IP 192.168.1.10\n");

    FILE *fp = popen("ip -4 addr show eth0 | grep inet | head -1", "r");
    char line[128] = {0};
    if (fp) {
        fgets(line, sizeof(line), fp);
        pclose(fp);
    }

    if (strlen(line) == 0) {
        printf("  [INFO] Setting static IP 192.168.1.10/24\n");
        system("ip addr add 192.168.1.10/24 dev eth0 2>/dev/null");
        system("ip link set eth0 up 2>/dev/null");
        sleep(1);
        fp = popen("ip -4 addr show eth0 | grep inet | head -1", "r");
        if (fp) {
            fgets(line, sizeof(line), fp);
            pclose(fp);
        }
    }

    if (strlen(line) > 0)
        printf("  [OK]   %s", line);
    else
        printf("  [FAIL] No IPv4 address on eth0\n");

    ret = system("ping -c 3 -W 2 8.8.8.8 > /dev/null 2>&1");
    printf("  [%s] Ping 8.8.8.8\n", (ret == 0) ? "OK " : "FAIL (check cable/DHCP)");
}

/* -------------------------------------------------- */
/* Test: HDMI Input (V4L2)                            */
/* -------------------------------------------------- */

void test_hdmi_in(void)
{
    printf("\n[TEST 6] HDMI Input Test (V4L2)\n");

    if (access("/dev/video0", F_OK) != 0) {
        printf("  [SKIP] /dev/video0 not found (no HDMI input)\n");
        return;
    }
    printf("  [OK]   /dev/video0 found\n");

    /* Check format */
    int ret = system("v4l2-ctl --device=/dev/video0 --list-formats-ext 2>/dev/null | head -10");
    if (ret != 0)
        printf("  [WARN] v4l2-ctl not available\n");

    printf("  [INFO] Connect HDMI source, then run:\n");
    printf("         v4l2-ctl --device=/dev/video0 --stream-mmap --stream-count=1 --stream-to=hdmi_in.raw\n");
}

/* -------------------------------------------------- */
/* Test: Memory                                       */
/* -------------------------------------------------- */

void test_memory(void)
{
    printf("\n[TEST 9] Memory/System Test\n");

    FILE *fp = fopen("/proc/meminfo", "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp)) {
            if (strstr(line, "MemTotal")) {
                printf("  [OK]   %s", line);
                break;
            }
        }
        fclose(fp);
    }

    fp = fopen("/proc/cpuinfo", "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp)) {
            if (strstr(line, "Hardware") || strstr(line, "model name")) {
                printf("  [OK]   %s", line);
                break;
            }
        }
        fclose(fp);
    }

    fp = popen("uname -a", "r");
    if (fp) {
        char line[256];
        if (fgets(line, sizeof(line), fp))
            printf("  [OK]   %s", line);
        pclose(fp);
    }
}

/* -------------------------------------------------- */
/* Test: HDMI (DRM check)                             */
/* -------------------------------------------------- */

void test_hdmi(void)
{
    printf("\n[TEST 6] HDMI Output Test\n");

    if (access("/dev/fb0", F_OK) == 0) {
        printf("  [OK]   /dev/fb0 found\n");
    } else {
        printf("  [WARN] /dev/fb0 not found, checking DRM...\n");
        DIR *dir = opendir("/sys/class/drm");
        if (dir) {
            struct dirent *entry;
            int found = 0;
            while ((entry = readdir(dir)) != NULL) {
                if (strstr(entry->d_name, "HDMI") ||
                    strstr(entry->d_name, "card")) {
                    printf("  [OK]   DRM: %s\n", entry->d_name);
                    found = 1;
                }
            }
            closedir(dir);
            if (!found)
                printf("  [FAIL] No HDMI DRM connector\n");
        }
    }
}

/* -------------------------------------------------- */
/* Main                                               */
/* -------------------------------------------------- */

int main(void)
{
    printf("==============================================\n");
    printf("  Zybo Z7-20 Hardware Test (UIO version)\n");
    printf("==============================================\n");

    test_memory();
    test_leds();
    test_switches();
    test_buttons();
    test_network();
    test_hdmi();
    test_hdmi_in();

    printf("\n==============================================\n");
    printf("  All tests completed\n");
    printf("==============================================\n");

    return 0;
}