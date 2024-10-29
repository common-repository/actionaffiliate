#!/usr/bin/perl
#
# SimpleGet.pl  -- standalone replacement for LWP::Simple
#
# This is a fairly minimal implementation of the HTTP GET protocol in
# Perl. It only does the 'GET' method via http (not https), and handles
# proxies and redirects but nothing more complicated. It is designed to
# be a simple replacement for the LWP library for scripts that only
# use the get(), getprint() and/or getstore() routines.
#
# It should be noted that web client Perl scripts fall into two general
# categories: Simple scripts that just get a page and grab one small
# bit of information from it, and complex tools like browsers, robots,
# site-shadowing utilities, custom search engines, etc. For the simple
# category, the LWP library and the other libraries it depends on
# (over 1.5 megabytes) is overkill.
#
# To use this code, put it in a file called "SimpleGet.pl" somewhere
# in your Perl @INC searchpath, such as /usr/lib/perl5/site_perl
# then add this line to your Perl script:
#
#   require "SimpleGet.pl";
#
# Each of the following is equivalent (except that the last creates
# a file "temp.html" in the current directory): They load the sample
# URL and print the HTML to STDOUT, and set $err to the HTTP result
# (usually 200, unless my ISP's server is down):
#
#   print get("http://www.mrob.com"); $err = $http_get_result;
#
#   $_ = get("http://www.mrob.com"); print $_; $err = $http_get_result;
#
#   $err = getprint("http://www.mrob.com");
#
#   $err = getstore("http://www.mrob.com", "temp.html");
#     system("cat temp.html");
#
# get() reads the data via HTTP and returns it. getprint() sends the
# data to STDOUT with relatively low memory overhead (useful if the
# data is large)
#
# This library also invites one-liner shell commands such as:
#
#   perl -e "require 'SimpleGet.pl'; getprint('http://www.mrob.com')"
#
# If you want to do anything more than loading simple pages and
# parsing their contents yourself, you should use LWP and the
# associated libraries. These libraries include such functions as MIME
# support, HTML parsing, handling of other transfer protocols like
# HTTPS and FTP, and much more. To learn more, see
# http://www.linpro.no/lwp/
#
# Existing web-client scripts that contain 'use LWP::Simple;' and only
# call the get() and/or getprint() functions can be converted to use
# SimpleGet by replacing the 'use LWP::Simple;' line with
# 'require "SimpleGet.pl";'
#
# Two extensions have been added to the functionality provided by the
# LWP get() and getprint() routines:
#   - Set $http_no_cache to 1 to force proxies to reload, or to 0 for
#     a normal GET.
#   - The variable $http_get_result is set to the result code (e.g. 200
#     or 404). (It is also returned by getprint() and getstore())
#
# Copyright, Usage, Feedback, etc:
#
#   This library is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# The minimal adaptation of LWP::Simple was created by Robert Munafo
# (www.mrob.com) from the LWP code. If you have problems, suggestions,
# or feedback regarding this file, please send them to "mrob at mrob
# dot com". Please don't bother Gisle Aas (the primary author of LWP)
# about it because it isn't his creation.
#
# 20000114 Initial version, derived from LWP::Simple, with minor additions
#   to handle http_proxy
# 20000117 Add $http_get_result and get_to_stdout().
# 20000118 Add $http_no_cache. Rename get_to_stdout() to getprint,
#   because that's what it's called in LWP.
# 20000119 Add getstore(), is_success() and "1;" at end; make it work
#   under "use strict;"
# 20000903 Add allow_post flag and POST handling; add post(), postprint(),
#   and poststore(). Reference:
#   http://www.oreilly.com/catalog/aspnut/chapter/ch06.html

require 5.004;
use strict vars;

my ($http_stream_out, %http_loop_check, $allow_post, $override_timeout);

sub _trivial_http_get
{
  my($host, $port, $path) = @_;
  my($AGENT, $VERSION, $p);
  my($ifpost, $postdata);
  #print "HOST=$host, PORT=$port, PATH=$path\n";

  $AGENT = "get-minimal";
  $VERSION = "20000118";

  $path =~ s/ /%20/g;
  if ($allow_post) {
    if ($path =~ m/^(.+)\?(.+)$/) {
      $path = $1; $postdata = $2;
      $ifpost = 1;
    } else {
      $ifpost = 0;
    }
  } else {
    $ifpost = 0;
  }

  require IO::Socket;
  local($^W) = 0;
  my $sock = IO::Socket::INET->new(PeerAddr => $host,
                                   PeerPort => $port,
                                   Proto   => 'tcp',
                                   Timeout  => 60) || return;
  $sock->autoflush;
  my $netloc = $host;
  $netloc .= ":$port" if $port != 80;
  my $request = ($ifpost ? "POST" : "GET")
              . " $path HTTP/1.0\015\012"
              . "Host: $netloc\015\012"
              . "User-Agent: $AGENT/$VERSION/u\015\012";
  $request .= "Pragma: no-cache\015\012" if ($main::http_no_cache);
  if ($ifpost) {
    $request .= "Content-type: application/x-www-form-urlencoded\015\012";
    $request .= "Content-length: " . length($postdata) . "\015\012";
  }
  $request .= "\015\012";
  if ($ifpost) {
    $request .= $postdata . "\015\012";
  }
  print $sock $request;

  my $buf = "";
  my $n;
  my $b1 = "";
  while ($n = sysread($sock, $buf, 8*1024, length($buf))) {
    if ($b1 eq "") { # first block?
      $b1 = $buf;         # Save this for errorcode parsing
      $buf =~ s/.+?\015?\012\015?\012//s;      # zap header
    }
    if ($http_stream_out) { print GET_OUTFILE $buf; $buf = ""; }
  }
  return undef unless defined($n);

  $main::http_get_result = 200;
  if ($b1 =~ m,^HTTP/\d+\.\d+\s+(\d+)[^\012]*\012,) {
    $main::http_get_result = $1;
    # print "CODE=$main::http_get_result\n$b1\n";
    if ($main::http_get_result =~ /^30[1237]/ && $b1 =~ /\012Location:\s*(\S+)/) {
      # redirect
      my $url = $1;
      return undef if $http_loop_check{$url}++;
      return _get($url);
    }
    return undef unless $main::http_get_result =~ /^2/;
  }

  return $buf;
}

sub _get
{
  my $url = shift;
  my $proxy = "";
  grep {(lc($_) eq "http_proxy") && ($proxy = $ENV{$_})} keys %ENV;
  if (($proxy eq "") && $url =~ m,^http://([^/:]+)(?::(\d+))?(/\S*)?$,) {
    my $host = $1;
    my $port = $2 || 80;
    my $path = $3;
    $path = "/" unless defined($path);
    return _trivial_http_get($host, $port, $path);
  } elsif ($proxy =~ m,^http://([^/:]+):(\d+)(/\S*)?$,) {
    my $host = $1;
    my $port = $2;
    my $path = $url;
    return _trivial_http_get($host, $port, $path);
  } else {
    return undef;
  }
}

sub get ($)
{
  $http_stream_out = 0;
  $allow_post = 0;

  %http_loop_check = ();
  goto \&_get;
}

sub getprint ($)
{
  my $url = shift;

  $allow_post = 0;
  $http_stream_out = 1;
  open(GET_OUTFILE, ">&STDOUT");
  %http_loop_check = ();
  _get($url);
  close GET_OUTFILE;
  return $main::http_get_result;
}

sub getstore ($$)
{
  my $url = shift;
  my $file = shift;

  $allow_post = 0;
  $http_stream_out = 1;
  open(GET_OUTFILE, "> $file");
  %http_loop_check = ();
  _get($url);
  close GET_OUTFILE;
  return $main::http_get_result;
}

sub post ($)
{
  $http_stream_out = 0;
  $allow_post = 1;

  %http_loop_check = ();
  goto \&_get;
}

sub postprint ($)
{
  my $url = shift;

  $allow_post = 1;
  $http_stream_out = 1;
  open(GET_OUTFILE, ">&STDOUT");
  %http_loop_check = ();
  _get($url);
  close GET_OUTFILE;
  return $main::http_get_result;
}

sub poststore ($$)
{
  my $url = shift;
  my $file = shift;

  $allow_post = 1;
  $http_stream_out = 1;
  open(GET_OUTFILE, "> $file");
  %http_loop_check = ();
  _get($url);
  close GET_OUTFILE;
  return $main::http_get_result;
}

sub is_success ($)
{
  my $code = shift;

  return ($code =~ /^2/);
}

1;
# end of SimpleGet.pl  013

