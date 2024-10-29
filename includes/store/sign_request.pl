#!/usr/bin/perl
#
#        sign_request.pl
#
#        Version 4.091210 - 10th December 2009
#
#        This version created by Labbs (http://www.labbs.com), with help from
#        Keith S.(ad104@yahoo.com).
#
#        This program is free software; you can redistribute it and/or modify
#        it under the terms of the GNU General Public License as published by
#        the Free Software Foundation; either version 2 of the License, or
#        (at your option) any later version.
#
#        This program is distributed in the hope that it will be useful,
#        but WITHOUT ANY WARRANTY; without even the implied warranty of
#        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#        GNU General Public License for more details.
#
#        You should have received a copy of the GNU General Public License
#        along with this program; if not, write to the Free Software
#        Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

sub sign_request {

        # External PERL modules required
        # Digest
        # Digest::SHA qw(hmac_sha256_base64)
        # or Digest::SHA::PurePerl qw(hmac_sha256_base64)

        # Try and load standard modules, but fallback to local PurePerl modules
        my @UseModules=qw(
        use Digest;
        use Digest::SHA;
        );
        for(@UseModules)
        {
        if($@){
        BEGIN{unshift @INC,"lib";$| =1;open(STDERR,">&STDOUT");}
        use Digest;
        use Digest::SHA::PurePerl qw(hmac_sha256_base64);
#	$debug .= qq[Using Local PurePerl Module<br>\n];
        }
        else{
        @UseModules;
#	$debug .= qq[Using Server C Module<br>\n];
        }}

        my ($value) = @_;

        my $MyTimeStamp = sprintf("%04d-%02d-%02dT%02d:%02d:%02d.000Z",
        sub {        ($_[5]+1900,
                 $_[4]+1,
                 $_[3],
                 $_[2],
                 $_[1],
                 $_[0])
                }->(gmtime(time)));

        my $stringToSign = $value . '&Timestamp=' . $MyTimeStamp . '&AWSAccessKeyId=' . $MY_variables{AWSAccessKey};

        # split the host from the request parameters
        my @request_elements = split('\?', $stringToSign);

        # Get the host and parameters
        my $request_host = $request_elements[0];
        my @request_parameters = split('&', $request_elements[1]);

        # Sort your parameter/value pairs by byte value (not alphabetically,
        #  lowercase parameters will be listed after uppercase ones).
        # Rejoin the sorted parameter/value list with ampersands. The result
        # is the canonical string that we'll sign:
        my $request_string = '';
        my @sorted_request_parameters = '';
        foreach my $parameter (sort(@request_parameters)) {
		# Uppercase URL % encoded characters as request signing expects them to be Upper Case
#		$debug .= qq[Parameter before necessary translations: '$parameter'<br />\n];
		$parameter =~ s/\%(.{2})/'%'.uc($1)/segi;
                # Encode comma (,) and colon (:) in parameters
                $parameter =~ s/[,]/'%2C'/seg;
                $parameter =~ s/[:]/'%3A'/seg;
                # Decode hyphen (-) encoded as %2d in parameters
                $parameter =~ s/%2D/'-'/segi;
                $parameter =~ s/%2E/'.'/segi;	#tc fix for having a dot in the author name (8th Dec 2009)
						# see http://www.absolutefreebies.com/phpBB2/viewtopic.php?p=61316#61316
#		$debug .= qq[Parameter after necessary translations: '$parameter'<br />\n];
                $request_string .= '&' . $parameter;
        }
        # Remove any leading & from our request string
        while(index($request_string, '&') == 0) {
                $request_string = substr($request_string, 1);
        }
#		$debug .= qq[Request String: '$request_string'<br />\n];

        # Prepend the following three lines (with line breaks) before the canonical string:
        # GET
        # webservices.amazon.com
        # /onca/xml

        my $stringToSign = "GET\n$Internal_variables{amazon_server}.$Internal_variables{amazon_site}\n/onca/xml\n" . $request_string;

        # Calculate an RFC 2104-compliant HMAC with the SHA256 hash algorithm
        my $signature = hmac_sha256_base64 ($stringToSign, $MY_variables{AWSSecretKey}) . "=";

        #  URL encode the plus (+) and equal (=) characters in the signature:
        $signature =~ s/[+]/'%2B'/seg;
        $signature =~ s/[=]/'%3D'/seg;

        #  Add the URL encoded signature to your request and the result is a
        #properly-formatted signed request:

        return $request_host . '?' . $request_string . '&Signature=' . $signature;
}

1;
# end of sign_request.pl

