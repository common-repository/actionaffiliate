#!/usr/bin/perl
#
#	apf4_banner.cgi
#
#	Version 4.091210 - 10th December 2009
#
#	This version created by Labbs (http://www.labbs.com) from an original
#	 script by MrRat (http://www.mrrat.com), with collaborative help from
#	 users of the APF Forum (http://www.absolutefreebies.com/phpBB2/)
#
#	You can support this script by making a donation at
#	 http://s1.amazon.com/exec/varzea/pay/T3M26803DZOCMK
#
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
#	! WARNING ! WARNING ! WARNING ! WARNING ! WARNING ! WARNING ! WARNING !
#	 Do not change the subscription_id.
#	  Doing so will violate your license to use this product.


use strict;
our ( $debug,$link_to_apf,$location_of_apf,%associate_ids,%Internal_variables,%MY_variables,%FORM,%AWS_variables,%time_zones );
use vars qw( $debug $link_to_apf $location_of_apf %associate_ids %Internal_variables %MY_variables %FORM %AWS_variables %time_zones );


######################################################
### basic options

## if you want this script to link to the APF script set the next option to "yes" and put the URL of the APF script in the following option
$link_to_apf = "yes";
$location_of_apf = "/shop/amazon_products_feed.cgi";

# to turn on debug mode include "_test" in the name of the script
if ($ENV{SCRIPT_NAME} =~ /_test\.cgi/) {
	if ($ENV{QUERY_STRING} !~ /cart_action/) {
		$| = 1; 
		open (STDERR, ">&STDOUT"); 
		if ($ENV{HTTP_REFERER} and $ENV{QUERY_STRING} !~ /myOperation/) {
			$MY_variables{continue_page} = $ENV{HTTP_REFERER};
			print qq[Set-Cookie: continue_page=$MY_variables{continue_page};\n];
		}
		print qq[Content-type: text/html\n\n]; 
	}
#$debug .= "<br>cookie: $ENV{'HTTP_COOKIE'}<br><br>\n";
	$Internal_variables{debug_state} = "on";
}

# load configuration
# begin find current directory
my $temp_path;
if($ENV{'PATH_TRANSLATED'}) {
	$temp_path = $ENV{'PATH_TRANSLATED'};
} else {
	$temp_path = $ENV{'SCRIPT_FILENAME'};
}
$temp_path =~ s|\\|/|g;
$Internal_variables{cwd} = substr($temp_path,0,rindex($temp_path,"/"));
# end find current directory

&load_config;
sub load_config {
	my $config_file = $Internal_variables{cwd} . "/apf_config.ini" || die qq[Problem opening config file at $Internal_variables{cwd}];
	if (!-s $config_file) {
		print "Location:apf_config.cgi\n\n";
		exit;
	}
	require $Internal_variables{cwd} . "/apf_config.ini";
}


&load_AWS_Keys;
sub load_AWS_Keys {
	my $AWS_Keys_file = $Internal_variables{AWS_Keys_File_Path} . '/' . $Internal_variables{AWS_Keys_File_Name} || die qq[Problem opening AWS Keys file at $Internal_variables{AWS_Keys_File_Path} . '/' . $Internal_variables{AWS_Keys_File_Name}];
	if (!-s $AWS_Keys_file) {
		print "Location:apf_config.cgi\n\n";
		exit;
	}
	require $Internal_variables{AWS_Keys_File_Path} . '/' . $Internal_variables{AWS_Keys_File_Name};
}
$debug .= qq[AWS Access Key: $MY_variables{AWSAccessKey}<br>\n];
$debug .= qq[AWS Secret Key: $MY_variables{AWSSecretKey}<br>\n];

## for best effect you should add a Unicode charset META tag to the <HEAD> of your page
## like this: <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">

###  end basic options. that's all you need to change.
######################################################
### advanced options

##  between <!-- BEGIN BANNER HTML --> and <!-- END BANNER HTML --> is the HTML that formats the result. feel free to change it to whatever you want.
##  possible AWS_variables are: Title, FormattedPrice, Availability, ASIN, Author, Publisher
##  possible MY_variables are: result_link, image_url_small, amazon_site
sub set_html {
my $banner_html = '';
if ($Internal_variables{debug_state} eq "on") {
    $banner_html .= qq[$debug];
}
$banner_html .= qq[
<!-- BEGIN BANNER HTML -->
<TABLE Bgcolor="#F1F1F1" Border="1" Width="468">
 <TR>
  <TD>
  <TABLE Bgcolor="#FFFFFF" Border="0" Cellpadding="0" Cellspacing="0" Width="100%">
   <TR>
    <TD Align="left">
     <A Href="$MY_variables{result_link}">
      <IMG Border="0" Src="$MY_variables{image_url_small}">
     </A>
    </TD>
    <TD Align="center">
     <FONT Size="4">
       <B>
        <A Href="$MY_variables{result_link}">
         $AWS_variables{Title}
        </A>
       </B>
      </FONT>
      <BR>
      <FONT Size="1">
       In association with $Internal_variables{amazon_wwwsite}
      </FONT>
      <BR>
      <FONT Size="1">
       Product price accurate as of $MY_variables{time_stamp}
       <BR>
       and is subject to change.
      </FONT>
     </TD>
     <TD Align="right">
      <FONT Color="red" Size="4">
       <B>
        $AWS_variables{FormattedPrice}
       </B>
      </FONT>
     </TD>
    </TR>
   </TABLE>
  </TD>
 </TR>
</TABLE>
<FONT Size="1">
 <A Href="http://www.mrrat.com/scripts.html" Target="_new">
  script by MrRat
 </A>
 , Updated by 
 <A HREF="http://www.labbs.com" Target="_new">
  LABBS
 </A>
</FONT>
<!-- END BANNER HTML -->
]; }

## if you are familiar with ResponseGroup in ECS you can change these to get different AWS_variables
$MY_variables{ResponseGroups} = "Images,ItemAttributes,OfferFull";

### end advanced options. the code is below.
######################################################


$MY_variables{subscription_id} = "09FVDRT8TEJ64C2A7Y02";
$Internal_variables{amazon_server} = "ecs";
$Internal_variables{amazon_domain} = "amazonaws";
$Internal_variables{amazon_wwwdomain} = "amazon";

get_url_input();
initialize_locale();
my $cwd = find_current_directory();
my $xml_result = get_url($cwd);
my ($random_details,$error_msg) = select_random_product($xml_result);
build_product($random_details);
my $html = set_html();
build_the_page($html,$error_msg);
exit;


sub find_current_directory {
	my $temp_path;
	if($ENV{'PATH_TRANSLATED'}) {
		$temp_path = $ENV{'PATH_TRANSLATED'};
	} else {
		$temp_path = $ENV{'SCRIPT_FILENAME'};
	}
	if ($temp_path) {
		$temp_path =~ s|\\|/|g;
		return substr($temp_path,0,rindex($temp_path,"/"));
	}
}

sub get_url_input {
	my ($form_pair,$form_name,$form_value,$item);
	if ($ENV{QUERY_STRING}) {
		for $form_pair (split(/&/, $ENV{QUERY_STRING})) {
			$form_pair =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
			$form_pair =~ s/[\;|\`|\\|\"|\||\?|\~|\<|\>|\^|\[|\]|\{|\}|\$]/ /g;
			($form_name, $form_value) = split(/=/, $form_pair);
			if ($form_name eq $form_value) { $form_value = ""; }
			$FORM{$form_name} = $form_value;
		}
	}
	foreach $item (@ARGV) {
		($form_name, $form_value) = split(/=/, $item);
		$FORM{$form_name} = $form_value;
	}
	if ($FORM{locale}) { $MY_variables{current_locale} = $FORM{locale} }
	if ($MY_variables{current_locale} !~ /^(ca|de|fr|jp|uk|us)$/) { $MY_variables{current_locale} = $MY_variables{default_locale}; }
}

sub initialize_locale {
	$MY_variables{associate_id} = $associate_ids{$MY_variables{current_locale}};
	my @associate_ids = @{$associate_ids{$MY_variables{current_locale}}};
	if ($FORM{associate_ids} and @associate_ids[$FORM{associate_ids}-1]) {
		$MY_variables{associate_id} = @associate_ids[$FORM{associate_ids}-1];
	} else {
		$MY_variables{associate_id} = @associate_ids[0];
	}
	my @time_zones = (@{$time_zones{$MY_variables{current_locale}}});
	if ($MY_variables{current_locale} eq "ca") {
		$Internal_variables{amazon_country} = "ca";
		$MY_variables{amazon_base_url} = "http://www.amazon.ca/exec/obidos/ASIN/";
	} elsif ($MY_variables{current_locale} eq "de") {
		$Internal_variables{amazon_country} = "de";
		$MY_variables{amazon_base_url} = "http://www.amazon.de/exec/obidos/ASIN/";
	} elsif ($MY_variables{current_locale} eq "fr") {
		$Internal_variables{amazon_country} = "fr";
		$MY_variables{amazon_base_url} = "http://www.amazon.fr/exec/obidos/ASIN/";
	} elsif ($MY_variables{current_locale} eq "jp") {
		$Internal_variables{amazon_country} = "jp";
		$MY_variables{amazon_base_url} = "http://www.amazon.co.jp/exec/obidos/ASIN/";
	} elsif ($MY_variables{current_locale} eq "uk") {
		$Internal_variables{amazon_country} = "co.uk";
		$MY_variables{amazon_base_url} = "http://www.amazon.co.uk/exec/obidos/ASIN/";
	} else {
		$Internal_variables{amazon_country} = "com";
		$MY_variables{amazon_base_url} = "http://www.amazon.com/exec/obidos/ASIN/";
	}
	$Internal_variables{amazon_url} = "http://www.amazon." . $Internal_variables{amazon_country} . "/gp/redirect.html?location=%2F&tag=$MY_variables{associate_id}&SubscriptionId=$MY_variables{subscription_id}";
	$Internal_variables{amazon_site} = $Internal_variables{amazon_domain} . "." . $Internal_variables{amazon_country};
	$Internal_variables{amazon_wwwsite} = $Internal_variables{amazon_wwwdomain} . "." . $Internal_variables{amazon_country};
	if ($MY_variables{current_locale} eq 'jp') {
	    $Internal_variables{amazon_wwwsite} = $Internal_variables{amazon_wwwdomain} . ".co." . $Internal_variables{amazon_country};
	}

	# Get the system time value (which is referenced to UTC)
	my $system_time = time();
	
	# Calculate new time from UTC offset
	my $time_difference = $time_zones[2] * 3600;
	
	# Adjust the time value
	my $adjusted_system_time = $system_time + $time_difference;

	# Get the time for the locale
	my @time_array = localtime($adjusted_system_time);

	if ($time_array[8] == 0) {
		push(@time_array, $time_zones[0]);
	}elsif($time_array[8] == 1){
		push(@time_array, $time_zones[1]);
	}else{
		push(@time_array, 'UNKNOWN');
	}

	# Adjust month number to real month number
	 $time_array[4] += 1;

	# Adjust Year to be real year
	 $time_array[5] += 1900;


	# Day
	my $day = $time_array[3];
	my $day_format = '%02d';
	# Month
	my $month = $time_array[4];
	my $month_format =  '%02d';
	# Year
	my $year = $time_array[5];
	my $year_format =  '%04d';
	
	my $date_format = ''; # Initialize date format as blank string

	my $i = 0; # Array index
	for ($i = 3; $i <= 5; $i += 1 ) {
		if ( $time_zones[$i] eq 'd' ) {
			$date_format .= $day_format;
			$time_array[$i] = $day;
		}
		if ( $time_zones[$i] eq 'm' ) {
			$date_format .= $month_format;
			$time_array[$i] = $month;
		}
		if ( $time_zones[$i] eq 'y' ) {
			$date_format .= $year_format;
			$time_array[$i] = $year;
		}
	unless ($i == 5) {
		$date_format .= '/';
	}
	}

	$MY_variables{time_stamp} = sprintf("$date_format %02d:%02d %s",
	    ($time_array[3],
	     $time_array[4],
	     $time_array[5],
	     $time_array[2],
	     $time_array[1],
	     $time_array[9])
	     );
	$debug .= qq[Time Stamp: $MY_variables{time_stamp}<br />\n];
}

sub get_url {
	my $cwd = shift;
	my ($this_xml_url,$xml_result,$url_options,$signed_value);
#	my $base_url = "http://webservices.$MY_variables{amazon_site}/onca/xml?Service=AWSECommerceService&AssociateTag=$MY_variables{associate_id}&SubscriptionId=$MY_variables{subscription_id}&Version=2005-03-23&ResponseGroup=$MY_variables{ResponseGroups}";
	my $base_url = "http://$Internal_variables{amazon_server}.$Internal_variables{amazon_site}/onca/xml?Service=AWSECommerceService&AssociateTag=$MY_variables{associate_id}&SubscriptionId=$MY_variables{subscription_id}&Version=2005-03-23&ResponseGroup=$MY_variables{ResponseGroups}";
	if ($FORM{Operation}) {
		if ($FORM{Operation} eq "ItemSearch") {
			if ($FORM{Keywords}) {
				$FORM{Keywords} =~ s/\s/\%20/g;
				$FORM{Keywords} =~ s/\+/\%20/g;
				$url_options = "&Keywords=$FORM{Keywords}";
			}
			if ($FORM{BrowseNode}) {
				$url_options = "&BrowseNode=$FORM{BrowseNode}";
			}
			$this_xml_url = $base_url . "&Operation=ItemSearch&SearchIndex=$FORM{SearchIndex}&$url_options";
		} elsif ($FORM{Operation} eq "ItemLookup") {
			$this_xml_url = $base_url . "&Operation=ItemLookup&ItemId=$FORM{ItemId}";
		}
	}


	$debug .= qq[this_xml_url: '$this_xml_url'<br />\n];
	my $value = $this_xml_url;
	$value =~ s/ /%20/g;
	$value =~ s/BrowseNode=([^%&]+)%3A([^&]+)/BrowseNode=$1:$2/;



	my ($cache_age,$cache_expire,$cache_time,%xml_cache,$xml_result,$dbm_error);
	if ($FORM{ResponseGroup} =~ /Large|Medium|Offer|SellerListing/) {
		$cache_age = 3600;
	} else {
		$cache_age = 86400;
	}
	$cache_expire = time() - $cache_age; $cache_time = $value . "_time";
#	if ($Internal_variables{use_cache} eq "Yes" and $Internal_variables{debug_state} ne "on") {
	if ($Internal_variables{use_cache} eq "Yes") {
		$debug .= qq[Caching is ON<br />\n];
		eval 'use Fcntl'; $dbm_error = $@;
		eval 'use DB_File'; $dbm_error .= $@;
		if (!$dbm_error) {
			if (-s $Internal_variables{cache_file} > (7000 * $Internal_variables{cache_max_size})) { unlink $Internal_variables{cache_file}; }
			eval 'tie(%xml_cache,"DB_File",$Internal_variables{cache_file},O_RDONLY)'; $dbm_error = $@;
			$debug .= qq[Reading from Cache file<br />\n];
			$debug .= qq[XML_CACHE value: '$xml_cache{$value}'<br />\n];
			$debug .= qq[XML_CACHE cache_time: '$xml_cache{$cache_time}'<br />\n];
			$debug .= qq[cache_expire: '$cache_expire'<br />\n];
		}else{
			$debug .= qq[!! DBM ERROR !!<br />\n];
		}
	}
	if ($xml_cache{$value} and $xml_cache{$cache_time} > $cache_expire) {
		$debug .= qq[Using Cached XML result<br />\n];
		$xml_result = $xml_cache{$value};
		untie %xml_cache;
	} else {
		$debug .= qq[NOT Using XML Cache<br />\n];
		untie %xml_cache;
		if ($cwd) {
			$debug .= qq[<a href="$this_xml_url" target="xml">XML Request</a><br />\n];
			require $cwd . "/simpleget.pl";
			# load request signing routine
			my $test = require $cwd . "/sign_request.pl";
			require $cwd . "/sign_request.pl";
			$signed_value = sign_request($this_xml_url);
			$debug .= qq[<a href="$signed_value" target="xml">Signed XML Request</a><br />\n];
			$xml_result = get($signed_value);
		}
#			if ($Internal_variables{use_cache} eq "Yes" and $Internal_variables{debug_state} ne "on" and !$dbm_error) {
			if ($Internal_variables{use_cache} eq "Yes" and !$dbm_error) {
				$debug .= qq[Caching is ON and DBM OK<br />\n];
				my $count=0;
				open(LOCK, ">$Internal_variables{cache_file}.lock");
				until (flock(LOCK,2) or $count > 50) {
					sleep .10;
					++$count;
				}
				if ($count > 50) { $dbm_error = "lock failed"; }
				if (!$dbm_error) {
					eval 'tie(%xml_cache,"DB_File",$Internal_variables{cache_file},O_CREAT|O_RDWR)'; $dbm_error = $@;
					if (keys(%xml_cache) > $Internal_variables{cache_max_size}) { undef %xml_cache; $debug .= "cleared cache<br />\n"; }
				}
			}
			$xml_cache{$value} = $xml_result;
			$xml_cache{$cache_time} = time;
			$debug .= qq[Writing to Cache file<br />\n];
			$debug .= qq[XML_CACHE value: '$xml_cache{$value}'<br />\n];
			$debug .= qq[XML_CACHE cache_time: '$xml_cache{$cache_time}'<br />\n];
			$debug .= qq[cache_expire: '$cache_expire'<br />\n];
			untie %xml_cache;
			close(LOCK);
	}
	return $xml_result;
}

sub select_random_product {
	my $xml_result = shift;
	my (@Details,$random_details,$error_msg);
	if ($xml_result) {
		$xml_result =~ s/<Item(?:\s[^>]+)?>(.*?)<\/Item>/push @Details, $1;/gsie;
		if (@Details) {
			$random_details = $Details[rand @Details];
		} else {
			$error_msg = "Sorry no results are currently being returned for this query.";
			$xml_result =~ s/<ErrorMsg>([^<]+)<\/ErrorMsg>/$error_msg = $1;/esi;
		}
	}
	return ($random_details,$error_msg);
}

sub build_product {
	my $random_details = shift;
	if ($random_details) {
		$random_details =~ s/<SmallImage><URL>([^<]+)<\/URL>/$MY_variables{image_url_small} = $1/e;
		$random_details =~ s/<([^>]+)>([^<]+)<\/\1>/$AWS_variables{$1} = $2;/gsie;
	}
	if (!$MY_variables{image_url_small}) { $MY_variables{image_url_small} = "http://g-images.amazon.com/images/G/01/books/icons/books-no-image.gif"; }
	if ($link_to_apf eq "yes" and $AWS_variables{ASIN}) {
		$MY_variables{result_link} = $location_of_apf . "?Operation=ItemLookup&ItemId=$AWS_variables{ASIN}&locale=$FORM{locale}";
	} else {
		$MY_variables{result_link} = $MY_variables{amazon_base_url} . $AWS_variables{ASIN} . "/" . $MY_variables{associate_id};
	}
}

sub build_the_page {
	my ($html,$error_msg) = @_;
	if ($error_msg) { $html = $error_msg; }
	if ($FORM{input_output} and $FORM{input_output} eq "javascript") {
		$html =~ s/"/'/g;
		$html =~ s/\n/"\);\ndocument.write\("/g;
		$html = qq[document.write("] . $html . qq[");\n];
		$html =~ s/(document.write\(")?<\/?SCRIPT[^>]*>("\);)?//gi;
	}
	print "Content-type: text/html; charset=utf-8\n\n";
	print "$html\n";
}
