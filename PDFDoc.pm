
# Package Namespace is hardcoded. Modules must live in
# PGBuild::Modules

=comment

Copyright (c) 2003-2017, Andrew Dunstan

See accompanying License file for license details

=cut

package PGBuild::Modules::PDFDoc;

use PGBuild::Options;
use PGBuild::SCM;
use PGBuild::Utils qw(:DEFAULT $steps_completed);

use strict;
use warnings;

use File::Copy;
use File::Basename;

use vars qw($VERSION); $VERSION = 'REL_9';

my $hooks = {
	'build'        => \&build,
	'install'      => \&install,
};

sub setup
{
	my $class = __PACKAGE__;

	my $buildroot = shift;    # where we're building
	my $branch    = shift;    # The branch of Postgres that's being built.
	my $conf      = shift;    # ref to the whole config object
	my $pgsql     = shift;    # postgres build dir

    die "can't run this module with vpath builds"
      if $conf->{vpath};

	my $self = {
		buildroot => $buildroot,
		pgbranch  => $branch,
		bfconf    => $conf,
		pgsql     => $pgsql
	};
	bless($self, $class);

	register_module_hooks($self, $hooks);
	return;
}


sub build
{
	my $self = shift;

	return unless step_wanted('pdf-build');

	print time_str(), "building ", __PACKAGE__, "\n" if $verbose;

	my $make_jobs = $self->{bfconf}->{make_jobs} || 1;

	my $make_cmd = $self->{bfconf}->{make} || 'make';

	$make_cmd .= " -j $make_jobs" if $make_jobs > 1;

	my @log;
	my $status;

	@log = run_log("cd $self->{pgsql}/doc/src/sgml && " .
				   "$make_cmd postgres-A4.pdf && $make_cmd postgres-US.pdf");
	$status = $? >>8;
    main::writelog('make-pdfs',\@log);
    print "======== make pdfs log ===========\n",@log 
        if ($verbose > 1);

    main::send_result('Make-PDFs',$status,\@log) if $status;

	$steps_completed .= " make-PDFs";

	return;
}

sub install
{
	my $self = shift;

	return unless step_wanted('pdf-build');

	print time_str(), "installing ", __PACKAGE__, "\n" if $verbose;

	# doc_inst can point somewhere like /vagrant or /tmp
	# if not found put the files in the branch root
	
	my $inst = $self->{bfconf}->{doc_inst}
	  || "$self->{buildroot}/$self->{pgbranch}";

	my $pgver =
	  (run_log("grep ^VERSION.= $self->{pgsql}/src/Makefile.global"))[0];
	chomp $pgver;
	$pgver =~ s/VERSION = //;

	foreach my $pdf (glob("$self->{pgsql}/doc/src/sgml/*.pdf"))
	{
		my $newname=basename($pdf);
		$newname =~ s/(A4|US)/$pgver-$1/;
		copy ($pdf,"$inst/$newname");
	}

	$steps_completed .= " install-PDF";

	return;
}


1;
