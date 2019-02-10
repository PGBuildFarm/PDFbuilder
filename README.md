PostgreSQL PDF Doc builder
==========================

This is a Vagrant recipe for a PostgreSQL BuildFarm animal to build
the PDF docs.

The recipe supplies a special module to build the docs. The animal should
only run configure and the doc builder steps, and only a change in the
docs sources should trigger a build.

The machine it runs in needs to have sufficient memory, or fop will
fail when building the docs. Vagrant instances with 512Mb of memory will fail,
with 4Gb of memory they succeed. I don't know where the exact failure point
is.

The configuration setting `doc_inst` specifies where PDFs will be copied to.
If it's not set, they will be copied to the branch root of the buildfarm
animal.

This recipe is for a Centos/7 box, but would be easily adaptable to, say,
Debian/stretch.

To test, in the machine where this is installed, do:

```
su - docbuilder
```

and then

```
cd bf && ./run_build.pl --test
```


