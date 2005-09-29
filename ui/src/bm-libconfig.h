/*
 * bm-libconf.h - librairy bm-libconf.c headers
 *
 * Copyright (C) 2005 The Backup Manager Authors
 * See the AUTHORS file for details.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 */

#include <stdio.h>
#include <sys/types.h>

typedef struct bm_variable_data_S {
	char	*BM_VARIABLE_NAME;
	char	*BM_VARIABLE_DATA;
} bm_variable_data;

extern	bm_variable_data 	bm_config_data[];
typedef	unsigned short int	BM_Bool;

#define	BM_TRUE		1
#define	BM_FALSE	0
#define BM_NB_VARIABLE	26	
#define BM_BUFF_SIZE    1024
#define BM_TPL_FILE	"/usr/share/backup-manager/backup-manager.conf.tpl"

BM_Bool
bm_load_config (const char* conf_file);

BM_Bool
bm_write_config (const char *dest_file_name);

void 
bm_free_config();

void 
bm_display_config();

char* 
bm_get_variable_data (const char *bm_variable);

BM_Bool
bm_set_variable_data (const char *bm_variable, const char *bm_dada);
