#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <gtk/gtk.h>

#include "callbacks.h"
#include <stdio.h>

#include "interface.h"
#include "support.h"

#include "global_widgets.h"
#include "dyn_interfaces.h"

void
on_configuration_window_destroy        (GtkObject       *object,
                                        gpointer         user_data)
{
	exit(0);
}


/* Fill all the entries with the values of the file given */
void
on_confw_load_button_clicked           (GtkButton       *button,
                                        gpointer         user_data)
{

}


/* Reset every entries with the values from the file */
void
on_confw_reset_button_clicked          (GtkButton       *button,
                                        gpointer         user_data)
{

}

/* Save changes to the configuration file */
void
on_confw_save_button_clicked           (GtkButton       *button,
                                        gpointer         user_data)
{

}

/* choose a directory */
void
on_confw_BM_REPOSITORY_ROOT_button_clicked
                                        (GtkButton       *button,
                                        gpointer         user_data)
{
	const gchar *selected_filename;
        GtkWidget   *filesel;
	
	filesel = create_confw_repository_filesel();
	gtk_widget_show(filesel);
	/*
	selected_filename = gtk_file_selection_get_filename(filesel);
	printf ("fichier: %s\n", selected_filename);
	*/
}


void
on_confw_BM_REPOSITORY_SECURE_yes_toggled
                                        (GtkToggleButton *togglebutton,
                                        gpointer         user_data)
{

}


void
on_confw_BM_REPOSITORY_SECURE_no_toggled
                                        (GtkToggleButton *togglebutton,
                                        gpointer         user_data)
{

}

void 
on_confw_repository_filesel_ok_button 
					(GtkWidget *widget, 
					gpointer user_data) 
{
   GtkWidget *file_selector = GTK_WIDGET (user_data);
   const gchar *selected_filename;

   selected_filename = gtk_file_selection_get_filename (GTK_FILE_SELECTION (file_selector));
   g_print ("Selected filename: %s\n", selected_filename);
}


