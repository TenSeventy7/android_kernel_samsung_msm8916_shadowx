#
# Makefile for cpuidle.
#

obj-y += cpuidle.o driver.o governor.o sysfs.o governors/
obj-$(CONFIG_ARCH_NEEDS_CPU_IDLE_COUPLED) += coupled.o

obj-$(CONFIG_CPU_IDLE_CALXEDA) += cpuidle-calxeda.o
obj-$(CONFIG_ARCH_KIRKWOOD) += cpuidle-kirkwood.o
obj-$(CONFIG_MSM_PM) += lpm-levels.o  lpm-levels-of.o
obj-$(CONFIG_CX_VOTE_TURBO) += lpm-workarounds.o

# Kanged -O3 Optimizations by @SparXFusion
# -O3 optimisations
ccflags-y := -O3
subdir-ccflags-y := -O3
