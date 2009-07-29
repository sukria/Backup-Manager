package BackupManager::Dialog;

use strict;
use warnings;

use vars qw(@ISA @EXPORT);
@ISA = ('Exporter');
@EXPORT = qw(init_dialog print_info print_warning print_error);

use BackupManager::Logger;

my $dialog_verbose = 0;

sub should_log($) {
    my ($level) = @_;

    my $level_score = {
        debug => 0,
        info => 1,
        warning => 2,
        error => 3,
    };

    my $conf_level = $ENV{BM_LOGGER_LEVEL} || 'warning';
    return $level_score->{$level} >= $level_score->{$conf_level};
}

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

	info ($message) if should_log 'info';
	print STDOUT $message."\n" if $dialog_verbose;
}

sub print_warning
{
    my ($message) = @_;
	$message = "" unless defined $message;
    chomp $message;

	warning ($message) if should_log 'warning';
	print STDERR $message."\n" if $dialog_verbose;
}

sub print_error
{
    my ($message) = @_;
	$message = "" unless defined $message;
    chomp $message;

	error ($message) if should_log 'error';
	print STDERR $message."\n";
}

1;
