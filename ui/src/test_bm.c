#include "bm.h"

int main (int argc, char **argv) {

	char *conf_file = "/etc/backup-manager.conf";
	
	bm_load_conf(conf_file);

	bm_display_config();

	bm_free_config();


}
