#include <stdio.h>
#include "../src/bm-libconfig.h"
#include "../src/mem_manager.h"

int main (int argc, char **argv) 
{
	char	*conf_file = "/etc/backup-manager.conf";
	char	*toto;
	
	mem_handler_init();

	/*
	__add_slashes("ceci est \" un test", &toto);
	printf("toto : '%s'\n", toto);
	mem_free(toto);
	__strip_slashes("ceci est \\\" un test", &toto);
	printf("toto : '%s'\n", toto);
	mem_free(toto);
	return 0;
	*/
	
	if ( bm_load_config(conf_file) ) {

		bm_display_config();

		printf("la clef BM_NAME_FORMAT vaut : %s\n", bm_get_variable_data("BM_NAME_FORMAT"));
		bm_set_variable_data("BM_NAME_FORMAT", "ceci est un test");
		
		printf("la clef BM_NAME_FORMAT vaux maintenant : %s\n", bm_get_variable_data("BM_NAME_FORMAT"));
		bm_write_config("/tmp/toto.conf");
		
		mem_print_status();
		bm_free_config();
	} else {
		printf("impossible de lire la conf\n");
	}
	
	mem_print_status();
}
