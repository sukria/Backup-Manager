#!/usr/bin/perl
package BackupManager::Config;

=head1 NAME

BackupManager::Config - BackupManager's configuration module

=head1 DESCRIPTION

Basically, it's a Getopt wrapper and a conffile reader.

=cut

use strict;
use warnings;

=head1 FUNCTIONS

=head2 getopt()

Comes from debconf, thanks Joe ;)

first arg : $usage (text to be written on STDERR if help is needed).

@_ : GetOpt args.

=cut

our $usage;

sub getopt ($@) {
	my ($_usage, @args) = (@_);
	$usage = $_usage;

	my $showusage=sub { # closure
		print STDERR $_usage."\n";
		exit 1;
	};

	# don't load big Getopt::Long unless really necessary.
	return unless grep { $_ =~ /^-/ } @ARGV;
	
	require Getopt::Long;
	Getopt::Long::GetOptions(
		'help|h',	$showusage,
		@args,
	) || $showusage->();
}

=head1 AUTHOR

Alexis Sukrieh <sukria@sukria.net>

=cut

1;

