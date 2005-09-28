#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>

#include "callbacks.h"
#include "support.h"

#define GLADE_HOOKUP_OBJECT(component,widget,name) \
  g_object_set_data_full (G_OBJECT (component), name, \
    gtk_widget_ref (widget), (GDestroyNotify) gtk_widget_unref)

#define GLADE_HOOKUP_OBJECT_NO_REF(component,widget,name) \
  g_object_set_data (G_OBJECT (component), name, widget)


GtkWidget* create_confw_repository_filesel (void) {

   GtkWidget *file_selector;

   /* Create the selector */
   file_selector = gtk_file_selection_new ("Please choose the repository of your archives.");
   
   g_signal_connect (GTK_FILE_SELECTION (file_selector)->ok_button,
                     "clicked",
                     G_CALLBACK (on_confw_repository_filesel_ok_button),
                     file_selector);
   			   
   /* Ensure that the dialog box is destroyed when the user clicks a button. */
   g_signal_connect_swapped (GTK_FILE_SELECTION (file_selector)->ok_button,
                             "clicked",
                             G_CALLBACK (gtk_widget_destroy), 
                             file_selector);

   g_signal_connect_swapped (GTK_FILE_SELECTION (file_selector)->cancel_button,
                             "clicked",
                             G_CALLBACK (gtk_widget_destroy),
                             file_selector); 
   
   return (file_selector);
}
