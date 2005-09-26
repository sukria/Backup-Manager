/*
 * Memory Manager - a small library for handling malloc and free
 *
 * Copyright (C) 2003-2005 Alexis Sukrieh <sukria@sukria.net>
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. 
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#include "bm.h"
#include "mem_manager.h"
#include "strLcpy.h"

bm_variable_data bm_config_data[] = {
	{ "BM_NAME_FORMAT", "" },
	{ "BM_FILETYPE", "" },
	{ "BM_MAX_TIME_TO_LIVE", "" },
	{ "BM_DUMP_SYMLINKS", "" },
	{ "BM_ARCHIVES_PREFIX", "" },
	{ "BM_DIRECTORIES", "" },
	{ "BM_DIRECTORIES_BLACKLIST", "" },
	{ "BM_ARCHIVES_REPOSITORY", "" },
	{ "BM_USER", "" },
	{ "BM_GROUP", "" },
	{ "BM_UPLOAD_MODE", "" },
	{ "BM_UPLOAD_HOSTS", "" },
	{ "BM_UPLOAD_USER", "" },
	{ "BM_UPLOAD_PASSWD", "" },
	{ "BM_FTP_PURGE", "" },
	{ "BM_UPLOAD_KEY", "" },
	{ "BM_UPLOAD_DIR", "" },
	{ "BM_BURNING", "" },
	{ "BM_BURNING_MEDIA", "" },
	{ "BM_BURNING_DEVICE", "" },
	{ "BM_BURNING_METHOD", "" },
	{ "BM_BURNING_MAXSIZE", "" },
	{ "BM_LOGGER", "" },
	{ "BM_LOGGER_FACILITY", "" },
	{ "BM_PRE_BACKUP_COMMAND", "" },
	{ "BM_POST_BACKUP_COMMAND", "" }
};

void bm_load_conf(const char* conf_file) {

	FILE		*bm_file;
	char		*bm_variable_name;
	char		*bm_variable_data;
	char		tmp[BM_BUFF_SIZE];
	int		bm_read_char;
	int		offset = 0;
	int		index = 0;
	BM_Bool		next = BM_TRUE;
	size_t		bm_variable_data_size;
	
	
	if ( bm_file = fopen( conf_file, "r") ) {
		while ( !feof(bm_file) ) {
			if ( ( bm_read_char = fgetc(bm_file) ) != EOF ) {
				
				strip_space(bm_file);
				// comment
				if ( (char) bm_read_char == '#' ) {
					go_to_next_line(bm_file);
					continue;
				} 
				
				// empty line
				if ( (char) bm_read_char == '\n' ) {
					continue;
				}

				fseek(bm_file, -1 * sizeof(char) , SEEK_CUR); 

				// export
				if ( !read_export(bm_file) ) {
					continue;
				}
				strip_space(bm_file);
				
				// variable name
				bm_variable_name = bm_read_variable_name(bm_file);

				if ( !bm_is_variable_name(bm_variable_name, &index) ) {
					mem_free(bm_variable_name);
					continue;
				}


				mem_free(bm_variable_name);
				
				strip_space(bm_file);
			
				bm_variable_data = bm_read_variable_data(bm_file);
				bm_variable_data_size = strlen(bm_variable_data) + 1;
				
				bm_config_data[index].BM_VARIABLE_DATA = (char*) mem_alloc_with_name( bm_variable_data_size * sizeof(char), "bm_variable_data");
				string_copy(bm_config_data[index].BM_VARIABLE_DATA, bm_variable_data, bm_variable_data_size);
				
				mem_free(bm_variable_data);
			} 
		}

		fclose(bm_file);
	} else {
		perror("can't open configuration file");
	}

}

void bm_free_config () {

	int i;
	for ( i = 0 ; i < BM_NB_VARIABLE ; i++ ) {
		mem_free(bm_config_data[i].BM_VARIABLE_DATA);
	}

}

void bm_display_config() {

	int i;
	for ( i = 0 ; i < BM_NB_VARIABLE ; i++ ) {
		printf("%s = %s\n",bm_config_data[i].BM_VARIABLE_NAME,  bm_config_data[i].BM_VARIABLE_DATA);
	}

}

char*
bm_read_variable_data( FILE *file) {

	char	tmp[BM_BUFF_SIZE];	
	BM_Bool	next = BM_TRUE, data_start = BM_FALSE;
	int 	offset	= 0;
	int	read_char;
	size_t	name_size;
	char	*dest;
	
	while ( next && ( offset < BM_BUFF_SIZE ) ) {
		
		if ( ( read_char = fgetc(file) ) != EOF ) {
			
			if ( !data_start ) {
				if ( read_char == '"' ) {
					data_start = BM_TRUE;
					continue;
				} else {
					continue;
				}
			}
			
			if ( (char)read_char == '"' ) {
				next = BM_FALSE;
			} else {
				tmp[offset] = (char) read_char;
			}
		
		} else {
			next = BM_FALSE;
		}
		offset++;
	}
	
	tmp[offset-1] = '\0';
	name_size = strlen(tmp) + 1;
	
	dest = (char*) mem_alloc_with_name (name_size * sizeof(char), "dest_variable_data");

	string_copy(dest, tmp, name_size);
	
	return dest;
}

char *
bm_read_variable_name(FILE *file) {

	char	tmp[BM_BUFF_SIZE];	
	BM_Bool	next	= BM_TRUE;
	int 	offset	= 0;
	int	read_char;
	size_t	name_size;
	char	*dest;
	
	while ( next && ( offset < BM_BUFF_SIZE - 1 ) ) {
		if ( ( read_char = fgetc(file)) != EOF )  {
			if ( (char)read_char == ' ' || (char)read_char == '=' || (char)read_char == '%' ) {
				next = BM_FALSE;
			} else {
				tmp[offset] = (char) read_char;
			}
		} else {
			next = BM_FALSE;
		}
		offset++;
	}
	tmp[(offset - 1)] = '\0';
	
	name_size = strlen(tmp) + 1;
	dest = (char*) mem_alloc_with_name (name_size * sizeof(char), "dest_variable_name");
	string_copy(dest, tmp, name_size);

	return dest;
}

BM_Bool 
bm_is_variable_name (const char *variable, int *p_index ) {
	int 	i;
	BM_Bool	bm_variable_ok = BM_FALSE;
	
	for ( i = 0 ; i < BM_NB_VARIABLE ; i++ ) {
		if ( strcmp(variable , bm_config_data[i].BM_VARIABLE_NAME) == 0 ) {
			bm_variable_ok = BM_TRUE;
			*p_index = i;
		}
	}

	return bm_variable_ok;
}

void strip_space(FILE *file) {

	BM_Bool next = BM_TRUE;
	int read_char;
	
	while (next) {
		if ( ( read_char = fgetc(file) != EOF ) ) {
			if ( (char) read_char != ' ' ) {
				next = BM_FALSE;
				fseek(file, -1 * sizeof(char) , SEEK_CUR); 
			}
		} else {
			next = BM_FALSE;
		}
	};

}

void go_to_next_line(FILE *file) {

	int	read_char;
	BM_Bool	next;	
	
	next = BM_TRUE;
	
	while ( next ) {
		if ( (read_char = fgetc(file) ) != EOF ) {
			if ( (char) read_char == '\n')
				next = BM_FALSE;
		} else {
			next = BM_FALSE;
		}
	}

}


BM_Bool read_export (FILE *file) {
	
	char	tmp[BM_BUFF_SIZE];
	int	offset = 0;	
	int	read_char;
	BM_Bool	next = BM_TRUE;

	while ( next && ( offset < BM_BUFF_SIZE - 1 ) ) {
		if ( ( read_char = fgetc(file) ) != EOF ) {
			if ( (char)read_char == ' ' ) {
				next = BM_FALSE;
			} else {
				tmp[offset] = (char) read_char;	
			}
		} else {
			next = BM_FALSE;
		}
		offset++;
	}
	tmp[offset - 1 ] = '\0';
	
	if ( strcmp(tmp, "export") == 0 ) {
		return BM_TRUE;
	} else {
		return BM_FALSE;
	}
}

char* bm_get_variable_data (const char *bm_variable) {

	int index = 0;
	
	if ( bm_is_variable_name(bm_variable, &index) ) {
		return bm_config_data[index].BM_VARIABLE_DATA;
	} else {
		return NULL;
	}
	
}

void bm_set_variable_data (const char *bm_variable, const char *bm_dada) {
	
	int index = 0;

	if ( bm_is_variable_name(bm_variable, &index) ) {
		mem_free(bm_config_data[index].BM_VARIABLE_DATA);
		bm_config_data[index].BM_VARIABLE_DATA = (char*) mem_alloc( (strlen(bm_dada) + 1) * sizeof(char));
		string_copy(bm_config_data[index].BM_VARIABLE_DATA, bm_dada, (strlen(bm_dada) + 1) );
	}
}

void bm_write_conf (const char *dest_file_name) {

	FILE	*fh_in, *fh_out;
	char	*bm_variable_name;
	int	read_char;
	int	index 			= 0;
	BM_Bool	write_variable		= BM_FALSE;
	BM_Bool	read_variable		= BM_FALSE;
	BM_Bool	find_tpl_special_char	= BM_FALSE;
	
	if ( fh_in = fopen(BM_TPL_FILE, "r") ) {
		if ( fh_out = fopen(dest_file_name, "w") ) {
			while( (read_char = fgetc(fh_in)) != EOF ) {
				
				printf("%c", (char)read_char);
				if ( find_tpl_special_char ) {
					if ( (char)read_char == '%' ) {
						read_variable = BM_TRUE;
					} else {
						read_variable = BM_FALSE;
					}
					 
				}

				if ( read_variable ) {
					bm_variable_name = bm_read_variable_name(fh_in);
					if ( bm_is_variable_name( bm_variable_name, &index) ) {
						write_variable= BM_TRUE;
					}
					mem_free(bm_variable_name);
					
				}

				if ( write_variable ) {
					fwrite(bm_config_data[index].BM_VARIABLE_DATA, sizeof(char), strlen(bm_config_data[index].BM_VARIABLE_DATA) , fh_out);
					fputs("\"\n", fh_out);
					read_variable = BM_FALSE;
					write_variable = BM_FALSE;
					find_tpl_special_char = BM_FALSE;
					go_to_next_line(fh_in);
					continue;
				}
				
				if ( (char)read_char == '%' ) {
					find_tpl_special_char = BM_TRUE;
				} else {
					fputc( read_char, fh_out);
				}	
				
			}
			fclose(fh_out);
		} else {
			perror("can't open sav file");
		}
		fclose(fh_in);
	} else {
		perror("can't open template file");
	}

} 
