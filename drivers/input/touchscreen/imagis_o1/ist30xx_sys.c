/*
 *  Copyright (C) 2010,Imagis Technology Co. Ltd. All Rights Reserved.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/i2c.h>
#include <linux/delay.h>
#include <asm/unaligned.h>

#include <asm/io.h>
#include <mach/gpio.h>
#include <linux/regulator/consumer.h>
#include <linux/gpio.h>

#include "ist30xx.h"
#include "ist30xx_update.h"
#include "ist30xx_tracking.h"

/******************************************************************************
 * Return value of Error
 * EPERM  : 1 (Operation not permitted)
 * ENOENT : 2 (No such file or directory)
 * EIO    : 5 (I/O error)
 * ENXIO  : 6 (No such device or address)
 * EINVAL : 22 (Invalid argument)
 *****************************************************************************/

extern struct ist30xx_data *ts_data;
const u32 pos_cmd = cpu_to_be32(CMD_GET_COORD);
struct i2c_msg pos_msg[READ_CMD_MSG_LEN] = {
	{
		.flags = 0,
		.len = IST30XX_ADDR_LEN,
		.buf = (u8 *)&pos_cmd,
	},
	{ .flags = I2C_M_RD, },
};

int ist30xx_get_position(struct i2c_client *client, u32 *buf, u16 len)
{
	int ret, i;

	pos_msg[0].addr = client->addr;
	pos_msg[1].addr = client->addr;
	pos_msg[1].len = len * IST30XX_DATA_LEN,
	pos_msg[1].buf = (u8 *)buf,

	ret = i2c_transfer(client->adapter, pos_msg, READ_CMD_MSG_LEN);
	if (ret != READ_CMD_MSG_LEN) {
		tsp_err("%s: i2c failed (%d)\n", __func__, ret);
		return -EIO;
	}

	for (i = 0; i < len; i++)
		buf[i] = cpu_to_be32(buf[i]);

	return 0;
}

#if IST30XX_ENABLE_GESTURE
int ist30xx_cmd_gesture(struct i2c_client *client, int gesture)
{
	int ret = -EIO;

	if (gesture > 3)
		return ret;

	ret = ist30xx_write_cmd(client, CMD_SET_GESTURE_MODE, gesture);

	msleep(10);

	return ret;
}
#endif

int ist30xx_cmd_start_scan(struct i2c_client *client)
{
	int ret;

	ret = ist30xx_write_cmd(client, CMD_START_SCAN, 0);

	ist30xx_tracking(TRACK_CMD_SCAN);

	msleep(100);

	ts_data->status.noise_mode = true;

	return ret;
}

int ist30xx_cmd_calibrate(struct i2c_client *client)
{
	int ret = ist30xx_write_cmd(client, CMD_CALIBRATE, 0);

	ist30xx_tracking(TRACK_CMD_CALIB);

	tsp_info("%s\n", __func__);

	msleep(100);

	return ret;
}

int ist30xx_cmd_check_calib(struct i2c_client *client)
{
	int ret = ist30xx_write_cmd(client, CMD_CHECK_CALIB, 0);

	ist30xx_tracking(TRACK_CMD_CHECK_CALIB);

	tsp_info("*** Check Calibration cmd ***\n");

	msleep(20);

	return ret;
}

int ist30xx_cmd_update(struct i2c_client *client, int cmd)
{
	u32 val = (cmd == CMD_ENTER_FW_UPDATE ? CMD_FW_UPDATE_MAGIC : 0);
	int ret = ist30xx_write_cmd(client, cmd, val);

	ist30xx_tracking(TRACK_CMD_FWUPDATE);

	msleep(10);

	return ret;
}

int ist30xx_cmd_reg(struct i2c_client *client, int cmd)
{
	int ret = ist30xx_write_cmd(client, cmd, 0);

	if (cmd == CMD_ENTER_REG_ACCESS) {
		ist30xx_tracking(TRACK_CMD_ENTER_REG);
		msleep(100);
	} else if (cmd == CMD_EXIT_REG_ACCESS) {
		ist30xx_tracking(TRACK_CMD_EXIT_REG);
		msleep(10);
	}

	return ret;
}


int ist30xx_read_cmd(struct i2c_client *client, u32 cmd, u32 *buf)
{
	int ret;
	u32 le_reg = cpu_to_be32(cmd);

	struct i2c_msg msg[READ_CMD_MSG_LEN] = {
		{
			.addr = client->addr,
			.flags = 0,
			.len = IST30XX_ADDR_LEN,
			.buf = (u8 *)&le_reg,
		},
		{
			.addr = client->addr,
			.flags = I2C_M_RD,
			.len = IST30XX_DATA_LEN,
			.buf = (u8 *)buf,
		},
	};

	ret = i2c_transfer(client->adapter, msg, READ_CMD_MSG_LEN);
	if (ret != READ_CMD_MSG_LEN) {
		tsp_err("%s: i2c failed (%d), cmd: %x\n", __func__, ret, cmd);
		return -EIO;
	}
	*buf = cpu_to_be32(*buf);

	return 0;
}


int ist30xx_write_cmd(struct i2c_client *client, u32 cmd, u32 val)
{
	int ret;
	struct i2c_msg msg;
	u8 msg_buf[IST30XX_ADDR_LEN + IST30XX_DATA_LEN];

	put_unaligned_be32(cmd, msg_buf);
	put_unaligned_be32(val, msg_buf + IST30XX_ADDR_LEN);

	msg.addr = client->addr;
	msg.flags = 0;
	msg.len = IST30XX_ADDR_LEN + IST30XX_DATA_LEN;
	msg.buf = msg_buf;

	ret = i2c_transfer(client->adapter, &msg, WRITE_CMD_MSG_LEN);
	if (ret != WRITE_CMD_MSG_LEN) {
		tsp_err("%s: i2c failed (%d), cmd: %x(%x)\n", __func__, ret, cmd, val);
		return -EIO;
	}

	return 0;
}

static void ts_power_enable(int en)
{
	int ret;
	static struct regulator *vddo;

	tsp_info("%s %s\n", __func__, (en) ? "on" : "off");

	if (!vddo) {
		vddo = regulator_get(&ts_data->client->dev, "vddo");

		if (IS_ERR(vddo)) {
			tsp_err("%s: could not get vddo, rc = %ld\n",
				__func__, PTR_ERR(vddo));
			return;
		}
		ret = regulator_set_voltage(vddo, 1800000, 1800000);
		if (ret)
			tsp_err("%s: vddo set_level failed (%d)\n", __func__, ret);
	}

	if (en) {
		ret = regulator_enable(vddo);
		if (ret) {
			tsp_err("%s: vddo enable failed (%d)\n", __func__, ret);
			return;
		}
	} else {
		ret = regulator_disable(vddo);
		if (ret) {
			tsp_err("%s: vddo disable failed (%d)\n", __func__, ret);
			return;
		}
	}

	ret = gpio_direction_output(ts_data->dt_data->touch_en_gpio, en);
	if (ret) {
		tsp_err("%s: unable to set_direction for TSP_EN [%d]\n",
			__func__, ts_data->dt_data->touch_en_gpio);
	}
	tsp_info("%s: touch_en: %d, vddo: %d\n", __func__,
		gpio_get_value(ts_data->dt_data->touch_en_gpio),
		regulator_is_enabled(vddo));

}

int ist30xx_power_on(bool download)
{
	if (ts_data->status.power != 1) {
		tsp_info("%s()\n", __func__);
		ist30xx_tracking(TRACK_PWR_ON);
		/* VDD enable */
		msleep(5);
		/* VDDIO enable */
		ts_power_enable(1);
		if (download)
			msleep(8);
		else
			msleep(100);
		ts_data->status.power = 1;
	}

	return 0;
}


int ist30xx_power_off(void)
{
	if (ts_data->status.power != 0) {
		tsp_info("%s()\n", __func__);
		ist30xx_tracking(TRACK_PWR_OFF);
		/* VDDIO disable */
		msleep(5);
		/* VDD disable */
		ts_power_enable(0);
		msleep(50);
		ts_data->status.power = 0;
		ts_data->status.noise_mode = false;
	}

	return 0;
}


int ist30xx_reset(bool download)
{
	tsp_info("%s()\n", __func__);
	ist30xx_power_off();
	msleep(10);
	ist30xx_power_on(download);

	return 0;
}


int ist30xx_internal_suspend(struct ist30xx_data *data)
{
#if IST30XX_ENABLE_GESTURE
	ist30xx_reset(false);
	ist30xx_cmd_gesture(data->client, 3);
#else
	ist30xx_power_off();
#endif
	return 0;
}


int ist30xx_internal_resume(struct ist30xx_data *data)
{
#if IST30XX_ENABLE_GESTURE
	ist30xx_reset(false);
#else
	ist30xx_power_on(false);
#endif

	return 0;
}


int ist30xx_init_system(void)
{
	int ret;

	// TODO : place additional code here.
	ret = ist30xx_power_on(false);
	if (ret) {
		tsp_err("%s: ist30xx_init_system failed (%d)\n", __func__, ret);
		return -EIO;
	}

#if 0
	ret = ist30xx_reset(false);
	if (ret) {
		tsp_err("%s: ist30xx_reset failed (%d)\n", __func__, ret);
		return -EIO;
	}
#endif

	return 0;
}
