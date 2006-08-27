#!/usr/bin/perl
package BackupManager::Logger;

=head1 NAME

BackupManager::Logger - BackupManager's Logger engine.

=head1 DESCRIPTION

It's a nice to use wrapper on the top of syslog. 
Will provide one function per syslog level.

=head2 FUNCTIONS

debug, info, notice, warning, error, critic and alert behave
the same : take a string and log it with the appropriate level.

=cut

use Exporter ;
@ISA = ( 'Exporter' ) ;
@EXPORT = qw (
		&debug
		&info
		&notice
		&warning
		&error
		&critic
		&alert
);

use strict;
use warnings;
use Sys::Syslog qw(:DEFAULT setlogsock); 

sub basename($);
use constant DEFAULT_FACILITY => 'cron';

our $LOG_IS_ENABLED;
our $basename;

my $LOG_FLAGS	=	{
	debug	=>	1,
	info	=>	1,
	notice	=>	1,
	warning =>	1,
	err	=>	1,
	crit 	=>	1,
	alert	=>	1
};

my $g_prefix = "";

my %g_rh_label = (
	info    => 'info ',
	notice  => 'note ',
	err     => 'error',
	warning => 'warn ',
	debug   => 'debug',
	crit    => 'crit ',
	alert   => 'alert'
);

my $facility;


BEGIN {
	$basename = $0;
	$basename =~ s%^.*/%%;
	$facility=DEFAULT_FACILITY unless $facility=$ENV{BM_LOGGER_FACILITY};
	setlogsock('unix');		
	openlog($basename, 'pid', $facility);
}

END {
	closelog();
}

sub debug($)
{
	my ($message) = @_;
	return 0 unless defined $message and length $message;
	return log_with_syslog('debug', $message);
}

sub info($)
{
	my ($message) = @_;
	return 0 unless defined $message and length $message;
	return log_with_syslog('info', $message);
}

sub notice($)
{
	my ($message) = @_;
	return 0 unless defined $message and length $message;
	return log_with_syslog('notice', $message);
}

sub warning($)
{
	my ($message) = @_;
	return 0 unless defined $message and length $message;
	return log_with_syslog('warning', $message);
}

sub error ($)
{
	my ($message) = @_;
	return 0 unless defined $message and length $message;
	return log_with_syslog('err', $message);
}

sub critic ($)
{
	my ($message) = @_;
	return 0 unless defined $message and length $message;
	return log_with_syslog('crit', $message);
}

sub alert ($)
{
	my ($message) = @_;
	return 0 unless defined $message and length $message;
	return log_with_syslog('alert', $message);
}

sub basename($)
{
	my $full_path = shift;
	return undef unless defined $full_path;

	chomp($full_path);
	$full_path =~ s/\/*$//;
	my @words = split(/\//, $full_path);
	return $words[$#words];
}

sub log_with_syslog ($$)
{
	my ($level, $message) = @_;
	return 0 unless defined $level and defined $message;
	
	my $caller = 2;
	my ($package, $filename, $line, $fonction) = caller ($caller);

	$package  = "" unless defined $package;
	$filename = "" unless defined $filename;
	$line     = 0 unless defined $line;
	$fonction = $basename unless defined $fonction;
	$level = lc($level);
	$level = 'info' unless defined $level and length $level;
	return 0 unless $LOG_FLAGS->{$level}; 
	
	unless (defined $message and length $message) { 
		$message = "[void]";
	}

	my $level_str = $g_rh_label{$level};
	$message  = $level_str . " * $message";
	$message .= " - $fonction ($filename l. $line)" if $line;

	$message =~ s/%/%%/g;
	$message = $g_prefix . " > " . $message if (length $g_prefix); 
	return syslog($level, $message);
}
=head1 AUTHOR

Alexis Sukrieh <sukria@sukria.net>

=cut


1;
