package BackupManager::Dialog;

use strict;
use warnings;

use vars qw(@ISA @EXPORT);
@ISA = ('Exporter');
@EXPORT = qw(init_dialog print_info print_warning print_error);

use BackupManager::Logger;

my $dialog_verbose = 0;

sub init_dialog($)
{
    my ($verbose) = @_;
    $dialog_verbose = $verbose if defined $verbose;
}

sub print_info
{
    my ($message) = @_;
	$message = "" unless defined $message;
    chomp $message;

	info ($message);
	print STDOUT $message."\n" if $dialog_verbose;
}

sub print_warning
{
    my ($message) = @_;
	$message = "" unless defined $message;
    chomp $message;

	warning ($message);
	print STDERR $message."\n" if $dialog_verbose;
}

sub print_error
{
    my ($message) = @_;
	$message = "" unless defined $message;
    chomp $message;

	error ($message);
	print STDERR $message."\n";
}

1;
