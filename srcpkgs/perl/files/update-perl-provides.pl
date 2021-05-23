#!/usr/bin/perl
##
## Name:
## update-perl-provides
##
## Description:
## Patch the provides list in the perl package PKGBUILD. Scan the appropriate
## directories under the perl source tree for directories containing dists
## similar to CPAN dists. Search the files in the distributions for VERSION
## strings, which are perl expressions. Filters these version strings through
## the perl interpreter, then transform the dist. names and versions into
## package names and versions. Finally, we cut out the "provides" array from the
## template and replace it with the newer version.
##
## Usage:
## update-provides.pl [path to perl source tree] [path to template]
##
## Caveats:
## The path code is not platform independent and will only work in POSIX.
##
## Changelog:
## 07/25/14 JR Updated for void.
## 06/10/14 JD Rewrite from scratch for perl 5.20.0 and ArchLinux.
##
## Authors:
## Justin "juster" Davis <jrcd83@gmail.com>
## Juan RP <xtraeme@gmail.com>
##

use warnings;
use strict;

sub err
{
    print STDERR "$0: error: @_\n";
    exit 1;
}

## Extract the dist. name from its containing directory.
sub path_dist
{
    my($path) = @_;
    $path =~ s{^.*/}{};
    return $path;
}

## Create a path like $path/lib/Foo/Bar.pm for Foo::Bar.
sub lib_modpath
{
    my($path, $modname) = @_;
    $modname =~ s{::}{/}g;
    return "$path/lib/$modname.pm";
}

## Create a path to a file in the containing directory, named after
## the last segment of the module name, with suffix attached.
sub dumb_modpath
{
    my($path, $modname, $suffix) = @_;
    $modname =~ s{^.*::}{};
    return "$path/$modname$suffix";
}

## Find a source file contained in the directory that we can scrape the
## perl versions string from.
my %distmods = (
    'PathTools' => 'Cwd',
    'Scalar-List-Utils' => 'List::Util',
    'IO-Compress' => 'IO::Compress::Gzip',
);
sub dist_srcpath
{
    my($path) = @_;
    my $distname = path_dist($path);
    my $modname;
    if(exists $distmods{$distname}){
        $modname = $distmods{$distname};
    }else{
        $modname = $distname;
        $modname =~ s/-/::/g;
    }
    my @srcpaths = (
        lib_modpath($path, $modname),
        dumb_modpath($path, $modname, '.pm'),
        dumb_modpath($path, $modname, '_pm.PL'),
        dumb_modpath($path, '__'.$modname.'__', '.pm'),
        "$path/VERSION", # for podlators
    );
    for my $src (@srcpaths){
        return $src if(-f $src);
    }
    return undef;
}

## Scrape the version string for the module file or Makefile.PL.
sub scrape_verln
{
    my($srcpath) = @_;
    open my $fh, '<', $srcpath or die "open: $!";
    while(my $ln = <$fh>){
        if($ln =~ s/^.*VERSION *=>? *//){
            close $fh;
            return $ln;
        }
    }
    close $fh;
    err("failed to find VERSION in $srcpath");
}

## Scrape the version string from the module source file.
sub scrape_modver
{
    my($srcpath) = @_;
    return scrape_verln($srcpath);
}

## Scrape the version string from the Makefile.PL. (for libnet)
sub scrape_mkplver
{
    my($srcpath) = @_;
    my $verln = scrape_verln($srcpath);
    $verln =~ s/,/;/;
    return $verln;
}

## Scrape the version string from a file inside the dist dir.
sub distpath_ver
{
    my($distpath) = @_;
    my $srcpath = dist_srcpath($distpath);
    my $mkplpath = "$distpath/Makefile.PL";
    if(defined $srcpath){
        return scrape_modver($srcpath);
    }elsif(-f $mkplpath){
        return scrape_mkplver($mkplpath);
    }else{
        err("failed to scrape version from $distpath");
    }
}

## Search the base path for the dist dirs and extract their respective
## version strings.
sub find_distvers
{
    my($basepath) = @_;
    opendir my $dh, $basepath or die "opendir: $!";
    my @dirs = grep { -d $_ } map { "$basepath/$_" } grep { !/^[.]/ } readdir $dh;
    closedir $dh;

    my @distvers;
    for my $dpath (@dirs){
        push @distvers, [ path_dist($dpath), distpath_ver($dpath) ];
    }
    return @distvers;
}

## Maps an aref of dist name/perl version strings (perl expressions) to
## a package name and version string suitable for a PKGBUILD.
sub pkgspec
{
    my($dist, $ver) = @$_;
    ## print STDOUT "dist $dist\n";
    ## $dist =~ tr/-/./;
    #print STDOUT "1 dist $dist\n";
    #$dist =~ tr/_0-9.-//cd;
    #print STDOUT "2 dist $dist\n";
    $ver =~ tr/././s; # only one period at a time
    $ver =~ s/\A[.]|[.]\z//g; # shouldn't start or stop with a period
    $ver =~ s/(\d)_(\d)/$1.$2/g; # retain 1.12 < 1.12_01 < 1.13 order in xbps ...
    $ver =~ s/^([0-9.]+);/'$1';/; # ... then turn broken numeric literal into string
    $ver = eval $ver;
    my $rev = "_1";
    my $res = "perl-$dist-$ver" . $rev;
    return $res;
}

## Searches the perl source dir provided for a list of packages which
## correspond to the core distributions bundled within in.
sub perlcorepkgs
{
    my($perlpath) = @_;
    my @dirs = ("$perlpath/cpan", "$perlpath/dist");
    my @provs;
    for my $d (@dirs){
        if(!-d $d){
            err("$d is not a valid directory");
        }
        push @provs, map pkgspec, find_distvers($d);
    }
    return @provs;
}

## Formats the provided lines into a neatly formatted bash array. The first arg
## is the name of the bash variable to assign it to.
sub basharray
{
    my $vname = shift;

    ## Sort entries and surround with quotes.
    my @lns = sort map { qq{$_} } @_;
    $lns[0] = "$vname=\"$lns[0]";

    ## Indent lines for OCD geeks.
    if(@lns > 1){
        my $ind = length($vname) + 2;
        splice @lns, 1, @lns-1,
            map { (' ' x $ind) . $_ } @lns[1 .. $#lns];
    }

    $lns[$#lns] .= '"';
    return map { "$_\n" } @lns;
}

## Patch the PKGBUILD at the given path with a new provides array, overwriting
## the old one.
sub patchpb
{
    my $pbpath = shift;
    open my $fh, '<', $pbpath or die "open: $!";
    my @lines = <$fh>;
    close $fh;

    my($i, $j);
    for($i = 0; $i < @lines; $i++){
        last if($lines[$i] =~ /^provides="/);
    }
    if($i == @lines){
        err("failed to find provides array in xbps template");
    }
    for($j = $i; $j < @lines; $j++){
        last if($lines[$j] =~ /["]/);
    }
    if($j == @lines){
        err("failed to find end of provides array");
    }

    splice @lines, $i, $j-$i+1,
        basharray('provides', grep { !/win32|next/ } @_);

    ## Avoid corrupting the existing template in case of a crash, etc.
    if(-f "$pbpath.$$"){
        err("pbpath.$$ temporary file already exists, please remove it.");
    }
    open $fh, '>', "$pbpath.$$" or die "open: $!";
    print $fh @lines;
    close $fh or die "close: $!";
    rename "$pbpath.$$", "$pbpath" or die "rename: $!";

    return;
}

## Program entrypoint.
sub main
{
    if(@_ < 2){
        print STDERR "usage: $0 [perl source path] [template path]\n";
        exit 2;
    }
    my($perlpath, $pbpath) = @_;
    if(!-f $pbpath){
        err("$pbpath is not a valid file.");
    }elsif(!-d $perlpath){
        err("$perlpath is not a valid directory.");
    }else{
        patchpb($pbpath, perlcorepkgs($perlpath));
    }
    exit 0;
}

main(@ARGV);

# EOF
