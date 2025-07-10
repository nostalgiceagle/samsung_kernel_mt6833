# SPDX-License-Identifier: GPL-2.0

COMMON_SENSOR := imx355
CHECK_DRIVER_DIR := $(COMMON_SENSOR)_mipi_raw

ifneq ($(findstring $(CHECK_DRIVER_DIR), $(CONFIG_CUSTOM_KERNEL_IMGSENSOR)), )
obj-y += $(COMMON_SENSOR)u_dummy.o
else
obj-y += ../$(COMMON_SENSOR)_mipi_raw/
endif
