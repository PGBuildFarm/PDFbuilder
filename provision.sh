
case `uname -a` in
	*Debian*|*Ubuntu*)
		DEBIAN_FRONTEND=noninteractive apt-get install -y wget
		;;
	*el7*)
		yum install -y wget
		;;
esac

useradd -m -c "postgresql doc builder" docbuilder

cd ~docbuilder

cat > /tmp/bfscript <<-'EOF'
	mkdir bf
	cd bf
	wget -nv https://buildfarm.postgresql.org/downloads/latest-client.tgz 
	tar -z --strip-components=1 -xf latest-client.tgz
	cp build-farm.conf.sample build-farm.conf
	cp /vagrant/PDFDoc.pm PGBuild/Modules
	# just run our module
	sed -i 's/TestUpgrade TestDecoding/PDFDoc/' build-farm.conf
	# remove MSVC setup for neatness
	sed -i '/MSVC Setup/,/^[}]/d' build-farm.conf
	# remove all configure options, we want this very lean
	sed -i -e '/^\t\t *--with/d' -e '/^\t\t *--enable/d' build-farm.conf
	# change the animal name etc.
	sed -i 's/CHANGEME/PDFDocBuilder/' build-farm.conf
	# don't keep a mirror, reconsider if there is already a mirror
	sed -i 's/git_keep_mirror.*/git_keep_mirror => 0,/' build-farm.conf
	# reset triggers, run if and only if there has been a docs change
	# set up where to copy the files to - must exist
	sed -i 's/trigger_exclude.*/trigger_exclude => undef,/' build-farm.conf
	sed -i 's!trigger_include.*!trigger_include => qr[^doc/], doc_inst => q[/vagrant],!' build-farm.conf
	# by default we're only going to run configure and the doc-builder
	sed -i '$ i\
	$main::only_steps{"configure"} = 1 unless $main::only_steps;\
	$main::only_steps{"pdf-build"} = 1 unless $main::only_steps;\
	' build-farm.conf
	EOF

su docbuilder /tmp/bfscript

case `uname -a` in
	*Debian*|*Ubuntu*)
		DEBIAN_FRONTEND=noninteractive apt-get install -y\
					   git \
					   bison \
					   flex \
					   gcc \
					   ccache \
					   perl \
					   libwww-perl \
					   liblwp-protocol-https-perl \
					   zlib1g-dev \
					   libreadline-dev \
					   xsltproc \
					   libxml2-utils \
					   fop \
					   pandoc
		;;
	*el7*)
		yum install -y \
			git \
			bison \
			flex \
			gcc \
			ccache \
			perl \
			perl-Digest-SHA \
			perl-libwww-perl \
			perl-LWP-Protocol-https \
			zlib-devel \
			readline-devel \
			fop \
			pandoc
		;;
esac

# run once just to get the repo set up.
su docbuilder sh -c "cd bf && ./run_build.pl --test --only-steps=configure"
