# SPDX-License-Identifier: GPL-2.0

COMMON_SENSOR := gc02m1_mipi_raw
ifneq ($(findstring $(COMMON_SENSOR), $(CONFIG_CUSTOM_KERNEL_IMGSENSOR)), )
obj-y += gc02m1b_dummy.o
else
$(info use $(COMMON_SENSOR) device driver)
obj-y += ../$(COMMON_SENSOR)/gc02m1mipiraw_Sensor.o
endif
