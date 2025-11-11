/*
 * ALU AXI-Lite Device Driver for Zybo Z7-20
 * Engineer: 나무
 * Date: 2025-11-12
 *
 * This driver provides user-space access to the ALU hardware accelerator
 * through sysfs interface
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/slab.h>

#define DRIVER_NAME "alu_axi"
#define ALU_REG_SIZE 0x1000

/* Register offsets */
#define ALU_REG_OPERAND_A   0x00
#define ALU_REG_OPERAND_B   0x04
#define ALU_REG_OPCODE      0x08
#define ALU_REG_CONTROL     0x0C
#define ALU_REG_RESULT      0x10
#define ALU_REG_STATUS      0x14

/* ALU operations */
#define ALU_OP_ADD  0
#define ALU_OP_SUB  1
#define ALU_OP_MUL  2
#define ALU_OP_DIV  3
#define ALU_OP_MOD  4
#define ALU_OP_EQ   5
#define ALU_OP_GT   6
#define ALU_OP_LT   7

struct alu_local {
    void __iomem *base_addr;
    struct device *dev;
};

/* Write to ALU register */
static inline void alu_write_reg(struct alu_local *lp, unsigned int reg, u32 val)
{
    iowrite32(val, lp->base_addr + reg);
}

/* Read from ALU register */
static inline u32 alu_read_reg(struct alu_local *lp, unsigned int reg)
{
    return ioread32(lp->base_addr + reg);
}

/* Sysfs attribute: operand_a */
static ssize_t operand_a_show(struct device *dev,
                              struct device_attribute *attr, char *buf)
{
    struct alu_local *lp = dev_get_drvdata(dev);
    u32 val = alu_read_reg(lp, ALU_REG_OPERAND_A);
    return sprintf(buf, "%u\n", val & 0xFF);
}

static ssize_t operand_a_store(struct device *dev,
                               struct device_attribute *attr,
                               const char *buf, size_t count)
{
    struct alu_local *lp = dev_get_drvdata(dev);
    unsigned int val;
    
    if (kstrtouint(buf, 0, &val))
        return -EINVAL;
    
    if (val > 255)
        return -EINVAL;
    
    alu_write_reg(lp, ALU_REG_OPERAND_A, val);
    return count;
}
static DEVICE_ATTR_RW(operand_a);

/* Sysfs attribute: operand_b */
static ssize_t operand_b_show(struct device *dev,
                              struct device_attribute *attr, char *buf)
{
    struct alu_local *lp = dev_get_drvdata(dev);
    u32 val = alu_read_reg(lp, ALU_REG_OPERAND_B);
    return sprintf(buf, "%u\n", val & 0xFF);
}

static ssize_t operand_b_store(struct device *dev,
                               struct device_attribute *attr,
                               const char *buf, size_t count)
{
    struct alu_local *lp = dev_get_drvdata(dev);
    unsigned int val;
    
    if (kstrtouint(buf, 0, &val))
        return -EINVAL;
    
    if (val > 255)
        return -EINVAL;
    
    alu_write_reg(lp, ALU_REG_OPERAND_B, val);
    return count;
}
static DEVICE_ATTR_RW(operand_b);

/* Sysfs attribute: opcode */
static ssize_t opcode_show(struct device *dev,
                          struct device_attribute *attr, char *buf)
{
    struct alu_local *lp = dev_get_drvdata(dev);
    u32 val = alu_read_reg(lp, ALU_REG_OPCODE);
    return sprintf(buf, "%u\n", val & 0x7);
}

static ssize_t opcode_store(struct device *dev,
                           struct device_attribute *attr,
                           const char *buf, size_t count)
{
    struct alu_local *lp = dev_get_drvdata(dev);
    unsigned int val;
    
    if (kstrtouint(buf, 0, &val))
        return -EINVAL;
    
    if (val > 7)
        return -EINVAL;
    
    alu_write_reg(lp, ALU_REG_OPCODE, val);
    return count;
}
static DEVICE_ATTR_RW(opcode);

/* Sysfs attribute: enable */
static ssize_t enable_show(struct device *dev,
                          struct device_attribute *attr, char *buf)
{
    struct alu_local *lp = dev_get_drvdata(dev);
    u32 val = alu_read_reg(lp, ALU_REG_CONTROL);
    return sprintf(buf, "%u\n", val & 0x1);
}

static ssize_t enable_store(struct device *dev,
                           struct device_attribute *attr,
                           const char *buf, size_t count)
{
    struct alu_local *lp = dev_get_drvdata(dev);
    unsigned int val;
    
    if (kstrtouint(buf, 0, &val))
        return -EINVAL;
    
    if (val > 1)
        return -EINVAL;
    
    alu_write_reg(lp, ALU_REG_CONTROL, val);
    return count;
}
static DEVICE_ATTR_RW(enable);

/* Sysfs attribute: result (read-only) */
static ssize_t result_show(struct device *dev,
                          struct device_attribute *attr, char *buf)
{
    struct alu_local *lp = dev_get_drvdata(dev);
    u32 val = alu_read_reg(lp, ALU_REG_RESULT);
    return sprintf(buf, "%u\n", val & 0xFFFF);
}
static DEVICE_ATTR_RO(result);

static struct attribute *alu_attrs[] = {
    &dev_attr_operand_a.attr,
    &dev_attr_operand_b.attr,
    &dev_attr_opcode.attr,
    &dev_attr_enable.attr,
    &dev_attr_result.attr,
    NULL,
};
ATTRIBUTE_GROUPS(alu);

static int alu_probe(struct platform_device *pdev)
{
    struct alu_local *lp;
    struct resource *res;
    int ret;

    dev_info(&pdev->dev, "Probing ALU AXI device\n");

    lp = devm_kzalloc(&pdev->dev, sizeof(*lp), GFP_KERNEL);
    if (!lp)
        return -ENOMEM;

    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    lp->base_addr = devm_ioremap_resource(&pdev->dev, res);
    if (IS_ERR(lp->base_addr))
        return PTR_ERR(lp->base_addr);

    lp->dev = &pdev->dev;
    platform_set_drvdata(pdev, lp);

    /* Initialize ALU */
    alu_write_reg(lp, ALU_REG_OPERAND_A, 0);
    alu_write_reg(lp, ALU_REG_OPERAND_B, 0);
    alu_write_reg(lp, ALU_REG_OPCODE, 0);
    alu_write_reg(lp, ALU_REG_CONTROL, 0);

    dev_info(&pdev->dev, "ALU AXI device probed successfully at 0x%08x\n",
             (unsigned int)res->start);

    return 0;
}

static int alu_remove(struct platform_device *pdev)
{
    dev_info(&pdev->dev, "Removing ALU AXI device\n");
    return 0;
}

static const struct of_device_id alu_of_match[] = {
    { .compatible = "xlnx,alu-axi-lite-1.0", },
    { /* end of list */ },
};
MODULE_DEVICE_TABLE(of, alu_of_match);

static struct platform_driver alu_driver = {
    .driver = {
        .name = DRIVER_NAME,
        .of_match_table = alu_of_match,
        .dev_groups = alu_groups,
    },
    .probe = alu_probe,
    .remove = alu_remove,
};

module_platform_driver(alu_driver);

MODULE_AUTHOR("나무");
MODULE_DESCRIPTION("ALU AXI-Lite Driver for Zybo Z7-20");
MODULE_LICENSE("GPL");
MODULE_ALIAS("platform:" DRIVER_NAME);
