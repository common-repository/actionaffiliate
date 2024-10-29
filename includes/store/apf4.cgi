#!/usr/bin/perl
#
#	apf4.cgi
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


use strict vars;

our (
%AWS_variables,%MY_variables,%Internal_variables,%FORM,%language_text,%associate_ids,%store_to_browse,%catalog_to_mode,%lookup_store,%current_base_nodes,
%base_nodes_us,%base_nodes_uk,%base_nodes_de,%base_nodes_jp,%base_nodes_fr,%base_nodes_ca,%no_image_image_hash,%bad_nodes,%mod_use,%sort_hash_by_mode,%sort_hash,%child_nodes,%template_html,
@mod_files,@months,@descriptors,$debug,%language_dirs_hash,%template_dirs_hash,%time_zones,%adult_browsenodes
);
use vars qw(
%AWS_variables %MY_variables %Internal_variables %FORM %language_text %associate_ids %store_to_browse %catalog_to_mode %lookup_store
%current_base_nodes %no_image_image_hash %bad_nodes %mod_use %sort_hash_by_mode %sort_hash %child_nodes %template_html
@mod_files @months @descriptors $debug %language_dirs_hash %template_dirs_hash %time_zones %adult_browsenodes
);

# Additon to create extra template variable for peggylon
$MY_variables{no_format_artists} = ''; 

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


# load mods
foreach my $item (@mod_files) {
	if ($mod_use{$item} eq "Yes") {
		require $Internal_variables{mods_directory} . "/$item.mod";
	}
}
eval 'use HTML::Entities'; my $load_entities_error .= $@;
if ($load_entities_error) { $debug .= "error loading: HTML::Entities<br>\n"; }

# setup initial variables
$MY_variables{script_name} = $ENV{SCRIPT_NAME};
#  Do not change the subscription_id.  Doing so will violate your license to use this product.
$MY_variables{subscription_id} = "09FVDRT8TEJ64C2A7Y02";
$FORM{ItemPage} = 1;
$FORM{ReviewPage} = 1;
$FORM{ProductPage} = 1;
$FORM{max_results} = 50;
$Internal_variables{amazon_server} = "ecs";
$Internal_variables{amazon_domain} = "amazonaws";
$Internal_variables{amazon_wwwdomain} = "amazon";
my $wsdl_version = "2009-03-31";


# make it so
get_url_input();
initialize_locale();
load_language();
initialize_hashes();
START_PROCESSING_LABEL:
calculate_initial_variables();
build_products();
build_the_page__main();
exit;

#	the end - subs below

sub get_url_input {
	my ($form_pair,$form_name,$form_value);
	for $form_pair (split(/&/, $ENV{QUERY_STRING})) {
		$form_pair =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$form_pair =~ s/[\;|\`|\\|\||\?|\~|\<|\>|\^|\[|\]|\{|\}|\$]/ /g;
		($form_name, $form_value) = split(/=/, $form_pair);
		if ($form_name eq $form_value) { $form_value = ""; }
		$FORM{$form_name} = $form_value;
	}
	if (%FORM) {
		(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
		foreach my $item (@mod_files) {
			my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
			if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
		}
		if ($FORM{locale}) { $MY_variables{current_locale} = $FORM{locale} }
	}
#	if (!$MY_variables{current_locale}) { $MY_variables{current_locale} = $MY_variables{default_locale}; }
	if ($MY_variables{current_locale} !~ /^(ca|de|fr|jp|uk|us)$/) { $MY_variables{current_locale} = $MY_variables{default_locale}; }
	if ($FORM{Operation} eq "ItemSearch" and !($FORM{Keywords} or $FORM{Title} or $FORM{Power} or $FORM{BrowseNode} or $FORM{Artist} or $FORM{Author} or $FORM{Actor} or $FORM{Director} or $FORM{AudienceRating} or $FORM{Manufacturer} or $FORM{MusicLabel} or $FORM{Composer} or $FORM{Publisher} or $FORM{Brand} or $FORM{Conductor} or $FORM{Orchestra} or $FORM{TextStream} or $FORM{Cuisine} or $FORM{City} or $FORM{Neighborhood})) { delete $FORM{Operation}; }
}

sub initialize_locale {
	my @associate_ids = @{$associate_ids{$MY_variables{current_locale}}};
	my @time_zones = (@{$time_zones{$MY_variables{current_locale}}});

	# Load Base BrowseNodes and SearchIndexes for the Current Locale
	require $Internal_variables{locale_directory} . "/apf_base_nodes_" . $MY_variables{current_locale} . ".ini";
	require $Internal_variables{locale_directory} . "/apf_store_to_browse_" . $MY_variables{current_locale} . ".ini";


	if ($FORM{associate_ids} and @associate_ids[$FORM{associate_ids}-1]) {
		$MY_variables{associate_id} = @associate_ids[$FORM{associate_ids}-1];
	} else {
		$MY_variables{associate_id} = @associate_ids[0];
	}
	if ($MY_variables{current_locale} eq "ca") {
		$Internal_variables{amazon_country} = "ca";
		$Internal_variables{money_symbol} = "CDN&#36;";
	 	$Internal_variables{img_tracker_locale} = "15";
	} elsif ($MY_variables{current_locale} eq "de") {
		$Internal_variables{amazon_country} = "de";
		$Internal_variables{money_symbol} = "EUR ";
	 	$Internal_variables{img_tracker_locale} = "3";
	} elsif ($MY_variables{current_locale} eq "fr") {
		$Internal_variables{amazon_country} = "fr";
		$Internal_variables{money_symbol} = "EUR ";
	 	$Internal_variables{img_tracker_locale} = "8";
	} elsif ($MY_variables{current_locale} eq "jp") {
		$Internal_variables{amazon_country} = "jp";
		$Internal_variables{money_symbol} = "&#165;";
	 	$Internal_variables{img_tracker_locale} = "9";
	} elsif ($MY_variables{current_locale} eq "uk") {
		$Internal_variables{amazon_country} = "co.uk";
		$Internal_variables{money_symbol} = "&#163;";
	 	$Internal_variables{img_tracker_locale} = "2";
	} else {
		$Internal_variables{amazon_country} = "com";
		$Internal_variables{money_symbol} = "&#36;";
	 	$Internal_variables{img_tracker_locale} = "1";
	}
	$Internal_variables{amazon_url} = "http://www.amazon." . $Internal_variables{amazon_country} . "/gp/redirect.html?location=%2F&tag=$MY_variables{associate_id}&SubscriptionId=$MY_variables{subscription_id}";
	$Internal_variables{amazon_site} = $Internal_variables{amazon_domain} . "." . $Internal_variables{amazon_country};
	$Internal_variables{amazon_wwwsite} = $Internal_variables{amazon_wwwdomain} . "." . $Internal_variables{amazon_country};
#	$debug .= 'Amazon Country: \'' . $MY_variables{current_locale} . "'<br />\n";
	if ($MY_variables{current_locale} eq 'jp') {
	    $Internal_variables{amazon_wwwsite} = $Internal_variables{amazon_wwwdomain} . ".co." . $Internal_variables{amazon_country};
	}

	my $key_name = "nodes_to_use_$MY_variables{current_locale}";
	if ($Internal_variables{$key_name} and $Internal_variables{$key_name} ne "All") {
		my (%good_indexes);
		for my $item (split(/,/, $Internal_variables{$key_name})) { $good_indexes{$item} = "x"; }
		foreach my $key (keys %store_to_browse) {
			delete $store_to_browse{$key} unless exists $good_indexes{$store_to_browse{$key}};
		}
	}
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
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

sub load_language {
	%language_dirs_hash = %{load_subdir_names($Internal_variables{languages_directory})};
	if ($FORM{language}) {
		# never trust what someone types in
		if ($language_dirs_hash{$FORM{language}}) {
			$Internal_variables{language_location} = "$Internal_variables{languages_directory}/$FORM{language}";
		} else {
			delete $FORM{language};
			$Internal_variables{language_location} = "$Internal_variables{languages_directory}/default";
		}
	} elsif ($MY_variables{current_locale} eq "de") {
		$Internal_variables{language_location} = "$Internal_variables{languages_directory}/german";
	} elsif ($MY_variables{current_locale} eq "jp") {
		$Internal_variables{language_location} = "$Internal_variables{languages_directory}/japanese";
	} elsif ($MY_variables{current_locale} eq "fr") {
		$Internal_variables{language_location} = "$Internal_variables{languages_directory}/french";
	} else {
		$Internal_variables{language_location} = "$Internal_variables{languages_directory}/default";
	}
	require "$Internal_variables{language_location}/main.language";
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
}

sub load_subdir_names {
	my $temp_input = shift;
	my %results_hash;
	opendir(DIR, $temp_input);
	my @temp_dirs = readdir(DIR);
	closedir(DIR);
	foreach my $item (@temp_dirs) {
		if (-d "$temp_input/$item" and $item !~ /\./) { $results_hash{$item} = 1;}
	}
	return \%results_hash;
}

sub initialize_hashes {
	%catalog_to_mode = ( "Apparel" => "Apparel", "Automotive Parts and Accessories" => "Automotive", "Baby" => "Baby", "Beauty" => "Beauty", "Book" => "Books", "books" => "Books", "books-english" => "Books", "DVD" => "DVD", "dvd" => "DVD", "Electronics" => "Electronics", "electronics" => "Electronics", "books-french" => "ForeignBooks", "books-gurupa-us-subtier" => "ForeignBooks", "Home Improvement" => "Tools", "tools" => "Tools", "Gourmet" => "GourmetFood", "Grocery" => "GourmetFood", "Jewelry" => "Jewelry", "Watch" => "Jewelry", "Kitchen" => "Kitchen", "kitchen" => "Kitchen", "Home &amp; Garden" => "Kitchen", "Lawn &amp; Patio" => "OutdoorLiving", "garden" => "OutdoorLiving", "Magazine" => "Magazines", "Magazines" => "Magazines", "magazines" => "Magazines", "Music" => "Music", "music" => "Music", "Personal Computer" => "PCHardware", "Software" => "Software", "software" => "Software", "Toy" => "Toys", "toys" => "Toys", "Video" => "VHS", "video" => "VHS", "Video Games" => "VideoGames", "videogames" => "VideoGames", "Sporting Goods" => "SportingGoods", "Sports" => "SportingGoods", "sports" => "SportingGoods", "Photography" => "Photo", "Office Product" => "OfficeProducts", "Furniture" => "OfficeProducts", "CE" => "Electronics", "ce" => "Electronics", "Health and Personal Care" => "HealthPersonalCare", "health" => "HealthPersonalCare", "Health and Beauty" => "HealthPersonalCare", "Health &amp; Personal Care" => "HealthPersonalCare", "Wireless" => "Wireless", "Restaurant Menu" => "Restaurants", "Baby Product" => "Baby" );
	%lookup_store = reverse %store_to_browse;
	require $Internal_variables{locale_directory} . "/apf_sort_" . $MY_variables{current_locale} . ".ini";
	%no_image_image_hash = (
		"Default" => "http://g-images.amazon.com/images/G/01/x-site/icons/no-img-sm.gif", 
		"Apparel" => "http://g-images.amazon.com/images/G/01/apparel/general/apparel-no-image.gif",
		"Baby" => "http://g-images.amazon.com/images/G/01/baby/no-photo-baby.gif",
		"Books" => "http://g-images.amazon.com/images/G/01/books/icons/books-no-image.gif",
		"Classical" => "http://g-images.amazon.com/images/G/01/music/icons/music-no-image.gif",
		"DVD" => "http://g-images.amazon.com/images/G/01/dvd/icons/dvd-no-image.gif",
		"DigitalMusic" => "http://g-images.amazon.com/images/G/01/music/icons/music-no-image.gif",
		"Electronics" => "http://g-images.amazon.com/images/G/01/electronics/no-photo-ce.gif",
		"GourmetFood" => "http://g-images.amazon.com/images/G/01/gourmet/gourmet-no-image.gif",
		"Jewelry" => "http://g-images.amazon.com/images/G/01/jewelry/nav/jewelry-icon-no-image-avail.gif",
		"Kitchen" => "http://g-images.amazon.com/images/G/01/kitchen/placeholder-icon.gif",
		"Magazines" => "http://g-images.amazon.com/images/G/01/stores/magazines/no_cover_image.gif",
		"Music" => "http://g-images.amazon.com/images/G/01/music/icons/music-no-image.gif",
		"MusicTracks" => "http://g-images.amazon.com/images/G/01/music/icons/music-no-image.gif",
		"OfficeProducts" => "http://g-images.amazon.com/images/G/01/office-products/icons/no-photo-office-prod.gif",
		"OutdoorLiving" => "http://g-images.amazon.com/images/G/01/stores/garden/no-photo-lawn.gif",
		"PCHardware" => "http://g-images.amazon.com/images/G/01/computer/no-photo-computer.gif",
		"HealthPersonalCare" => "http://g-images.amazon.com/images/G/01/hpc/icon-hpc-noimageavail.gif",
		"Photo" => "http://g-images.amazon.com/images/G/01/photo/placeholder-icon.gif",
		"Software" => "http://g-images.amazon.com/images/G/01/software/new-item-1.gif",
		"SportingGoods" => "http://g-images.amazon.com/images/G/01/stores/sports-outdoors/sports-no-image.gif",
		"Tools" => "http://g-images.amazon.com/images/G/01/stores/hi/no-photo-tools.gif",
		"Toys" => "http://g-images.amazon.com/images/G/01/v9/icons/no-picture-icon.gif",
		"VHS" => "http://g-images.amazon.com/images/G/01/video/icons/video-no-image.gif",
		"Video" => "http://g-images.amazon.com/images/G/01/video/icons/video-no-image.gif",
		"VideoGames" => "http://g-images.amazon.com/images/G/01/videogames/icons/vg-not-available.gif",
		"Wireless" => "http://g-images.amazon.com/images/G/01/wireless/no-photo-lt-blue.gif",
	);
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
}

sub build_templates_location {
	%template_dirs_hash = %{load_subdir_names($Internal_variables{templates_directory})};
	if ($FORM{templates}) {
		# never trust what someone types in
		if ($template_dirs_hash{$FORM{templates}}) {
			$Internal_variables{templates_location} = "$Internal_variables{templates_directory}/$FORM{templates}";
		} else {
			delete $FORM{templates};
		}
	}
	if (!$FORM{link_templates} or !$template_dirs_hash{$FORM{link_templates}}) {
		$FORM{link_templates} = $FORM{templates};
	}
}

sub calculate_initial_variables {
	$MY_variables{SearchIndex} = $FORM{SearchIndex};
	if ($FORM{SearchIndex} =~ /node:|node%3A/) { $MY_variables{SearchIndex} =~ s/node:([^:]+):(.*)/$1/; $FORM{BrowseNode} = $2; }
	if (!$MY_variables{SearchIndex} and !$FORM{Operation} and !$FORM{myOperation} and $Internal_variables{there_can_be_only_one}) { $MY_variables{SearchIndex} = $Internal_variables{there_can_be_only_one}; }
	build_templates_location();
	if (!$FORM{link_max_results} and $FORM{max_results} != 50) { $FORM{link_max_results} = $FORM{max_results}; }
	$MY_variables{see_back} = qq[<a href="javascript:history.go(-1)" onmouseout="self.status='';return true" onmouseover="self.status=document.referrer;return true">$language_text{see_text3}</a>];
	$MY_variables{in_association} = qq[<a class="apf_small_text" href="$MY_variables{script_name}?go=amazon&amp;locale=$MY_variables{current_locale}">$language_text{association_text1}</a>];
	$Internal_variables{base_url} = "http://$Internal_variables{amazon_server}.$Internal_variables{amazon_site}/onca/xml?Service=AWSECommerceService&AssociateTag=$MY_variables{associate_id}&SubscriptionId=$MY_variables{subscription_id}&Version=$wsdl_version";

	if ($Internal_variables{display_adult} ne "Yes") {
		$debug .= qq[Adult BrowseNodes: '$adult_browsenodes{$MY_variables{current_locale}}'<br />\n];
		$Internal_variables{bad_nodes} .= $adult_browsenodes{$MY_variables{current_locale}}; 
	}

	for my $item (split(/,/, $Internal_variables{bad_nodes})) { if (!$bad_nodes{$item}) {$bad_nodes{$item} = "x";} }
	$ENV{'HTTP_COOKIE'} =~ s/continue_page=([^;]+)/$MY_variables{continue_page} = $1;/e;
	if ($MY_variables{continue_page}) {
		$MY_variables{continue_page_onclick} = qq[parent.location='$MY_variables{continue_page}'];
	} else {
		$MY_variables{continue_page_onclick} = qq[javascript:history.go(-1)];
	}
	# url, form, & see options
	delete $Internal_variables{url_options}; delete $MY_variables{form_options}; delete $Internal_variables{see_url_options}; delete $Internal_variables{query};
	if ($MY_variables{SearchIndex}) {
		$MY_variables{store} = $lookup_store{$MY_variables{SearchIndex}};
		if ($FORM{Operation} =~ /ItemSearch|SellerListingSearch/) { $Internal_variables{query} .= "&SearchIndex=$MY_variables{SearchIndex}"; }
		$Internal_variables{see_url_options} = "SearchIndex=$MY_variables{SearchIndex}";
		$Internal_variables{more_form_options} = qq[<input type="hidden" name="SearchIndex" value="$MY_variables{SearchIndex}" />];
	}
	if ($FORM{Operation} and !$FORM{BrowseNode}) {
		if ($Internal_variables{see_url_options}) { $Internal_variables{see_url_options} .= "&amp;"; }
		$Internal_variables{see_url_options} .= "Operation=$FORM{Operation}";
		$Internal_variables{more_form_options} .= qq[<input type="hidden" name="Operation" value="$FORM{Operation}" />];
	}
	if ($FORM{myOperation}) {
		if ($Internal_variables{see_url_options}) { $Internal_variables{see_url_options} .= "&amp;"; }
		$Internal_variables{see_url_options} .= "myOperation=$FORM{myOperation}";
		$Internal_variables{more_form_options} .= qq[<input type="hidden" name="myOperation" value="$FORM{myOperation}" />];
	}
	if ($FORM{ItemId}) {
		$Internal_variables{see_url_options} .= "&amp;ItemId=$FORM{ItemId}";
		$Internal_variables{more_form_options} .= qq[<input type="hidden" name="ItemId" value="$FORM{ItemId}" />];
	}
	if ($FORM{link_templates}) {
		$Internal_variables{url_options} .= "&amp;templates=$FORM{link_templates}";
		$MY_variables{form_options} .= qq[<input type="hidden" name="templates" value="$FORM{link_templates}" />];
	}
	if ($FORM{language}) {
		$Internal_variables{url_options} .= "&amp;language=$FORM{language}";
		$MY_variables{form_options} .= qq[<input type="hidden" name="language" value="$FORM{language}" />];
	}
	if ($FORM{locale}) {
		$Internal_variables{url_options} .= "&amp;locale=$FORM{locale}";
		$MY_variables{form_options} .= qq[<input type="hidden" name="locale" value="$FORM{locale}" />];
	}
	if ($FORM{link_max_results}) {
		$Internal_variables{url_options} .= "&amp;max_results=$FORM{link_max_results}";
		$MY_variables{form_options} .= qq[<input type="hidden" name="max_results" value="$FORM{link_max_results}" />];
	}
	if ($FORM{associate_ids}) {
		$Internal_variables{url_options} .= "&amp;associate_ids=$FORM{associate_ids}";
		$MY_variables{form_options} .= qq[<input type="hidden" name="associate_ids" value="$FORM{associate_ids}" />];
	}
	if ($FORM{ResponseGroup}) { $Internal_variables{see_url_options} .= "&amp;ResponseGroup=$FORM{ResponseGroup}"; }
	if (!$FORM{ResponseGroup}) {
		if ($FORM{Operation} =~ /ItemSearch|SimilarityLookup/ or $FORM{ItemId} =~ /,/) {
			$FORM{ResponseGroup} = $Internal_variables{ResponseGroup_Products};
			if ($FORM{SearchIndex} ne "Blended") { $Internal_variables{can_sort} = "Yes"; }
		} elsif ($FORM{Operation} eq "ListLookup") {
			$FORM{ResponseGroup} = $Internal_variables{ResponseGroup_Products} . ",ListItems";
		} elsif ($FORM{myOperation} eq "CustomerReviews") {
			$FORM{ResponseGroup} = $Internal_variables{ResponseGroup_Reviews};
		} elsif ($FORM{myOperation} eq "Image") {
			$FORM{ResponseGroup} = $Internal_variables{ResponseGroup_Image};
		} elsif ($FORM{Operation} eq "ItemLookup") {
			$FORM{ResponseGroup} = $Internal_variables{ResponseGroup_Item};
		}
	}
	delete $Internal_variables{persistant_parameters_query}; delete $Internal_variables{persistant_parameters_url_options}; delete $Internal_variables{persistant_parameters_form_options};
	foreach my $item ("Availability", "AudienceRating", "City", "Neighborhood", "MaximumPrice", "MinimumPrice", "Condition", "ISPUPostalCode", "MPAARating") {
		if ($FORM{$item}) {
			$MY_variables{subject} = $language_text{button_text4};
			(my $search_url = $FORM{$item}) =~ s/\+/ /g;
			$search_url = url_encode($search_url);
			$Internal_variables{persistant_parameters_query} .= "&$item=$search_url";
			$Internal_variables{persistant_parameters_url_options} .= "&amp;$item=$FORM{$item}";
			$Internal_variables{persistant_parameters_form_options} .= qq[<input type="hidden" name="$item" value="$FORM{$item}" />];
		}
	}
	foreach my $item ("ListType", "ListId", "Keywords", "Title", "BrowseNode", "Artist", "Author", "Actor", "Director", "Manufacturer", "MusicLabel", "Composer", "Publisher", "Brand", "Conductor", "Orchestra", "TextStream", "Sort", "Cuisine", "MerchantId", "DeliveryMethod", "ConditionType", "Count", "Power") {
		if ($FORM{$item}) {
			$MY_variables{subject} = $language_text{button_text4};
			my $search_url = $FORM{$item};
			if ($item ne "Sort") {
				$search_url =~ s/\+/ /g;
				$search_url = url_encode($search_url);
			} else {
				$search_url =~ s/\+/%2B/g;
			}
			if ($item eq "Keywords") {
				$search_url = lc($search_url);
				$Internal_variables{Keywords_escaped} = html_escape($FORM{Keywords});
				$Internal_variables{Keywords_encoded} = url_encode($FORM{Keywords});
				$FORM{$item} = $Internal_variables{Keywords_escaped};
			}
			$Internal_variables{query} .= "&$item=$search_url";
			$Internal_variables{see_url_options} .= "&amp;$item=$FORM{$item}";
			$Internal_variables{more_form_options} .= qq[<input type="hidden" name="$item" value="$FORM{$item}" />];
		}
	}
	$Internal_variables{query} .= $Internal_variables{persistant_parameters_query};
	$Internal_variables{see_url_options} .= $Internal_variables{persistant_parameters_url_options};
	$Internal_variables{more_form_options} .= $Internal_variables{persistant_parameters_form_options};
	if (!$Internal_variables{there_can_be_only_one}) {
		(my $temp_options = $Internal_variables{url_options}) =~ s/^&amp;//;
		$Internal_variables{bestsellers_header} = qq[<a href="$MY_variables{script_name}?$temp_options">$language_text{header_text1}</a> &gt; ];
	}
#	if ($FORM{BrowseNode}) {
#		($MY_variables{BrowseNodeName_display} = $FORM{BrowseNodeName}) =~ s/_/ /g;
#		$MY_variables{header} = qq[$Internal_variables{bestsellers_header}<a href="$MY_variables{script_name}?SearchIndex=$MY_variables{SearchIndex}$Internal_variables{url_options}">$MY_variables{store}</a> &gt; $MY_variables{BrowseNodeName_display}];
#$debug .= $MY_variables{BrowseNodeName_display} . "." . $AWS_variables{BrowseNodes} . "<br>";
#		my $temp_BrowseNodes = $AWS_variables{BrowseNodes};
#		recurse_Ancestors($temp_BrowseNodes,"","browseheader");
#		$MY_variables{header} = $Internal_variables{browse_header} = $MY_variables{browseheader};
#	}
	if ($FORM{Operation} eq "ItemSearch") {
		if ($FORM{ItemPage} > 1) { $Internal_variables{query} .= qq[&ItemPage=$FORM{ItemPage}]; }
		$Internal_variables{query} .= qq[&ResponseGroup=$FORM{ResponseGroup}];
	}
	if ($FORM{Operation} eq "ItemLookup" or $FORM{Operation} eq "SimilarityLookup") {
		if ($FORM{ReviewPage} > 1) { $Internal_variables{query} .= qq[&ReviewPage=$FORM{ReviewPage}]; }
		$Internal_variables{query} .= qq[&ItemId=$FORM{ItemId}&ResponseGroup=$FORM{ResponseGroup}];
	}
	if ($FORM{Operation} eq "ListLookup") {
		if ($FORM{ProductPage} > 1) { $Internal_variables{query} .= qq[&ProductPage=$FORM{ProductPage}]; }
		$Internal_variables{query} .= qq[&ResponseGroup=$FORM{ResponseGroup}];
	}
	# end url, form, & see options
	# begin cart stuff
	$ENV{'HTTP_COOKIE'} =~ s/apfcart_$MY_variables{current_locale}=([^,]+),([^;]+)/$AWS_variables{CartId} = $1; $AWS_variables{URLEncodedHMAC} = $2;/e;
	$ENV{'HTTP_COOKIE'} =~ s/apfcartcontents_$MY_variables{current_locale}=([^,]+),([^;]+)/$MY_variables{total_cart_items} = $1; $MY_variables{cart_price_total} = $2;/e;
	if ($AWS_variables{CartId} and $AWS_variables{URLEncodedHMAC}) { $Internal_variables{session} = qq[&CartId=$AWS_variables{CartId}&HMAC=$AWS_variables{URLEncodedHMAC}]; }
	if (!$FORM{cart_action}) {
		if ($Internal_variables{session}) {
			$MY_variables{shopping_cart_link} = qq[<span class="apf_cart_text3_style"><a href="$MY_variables{script_name}?cart_action=get$Internal_variables{url_options}">$language_text{cart_text3}</a></span>];
		}
	} else {
	}
	# end cart stuff
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
}

sub build_products {
	if ($FORM{cart_action}) {
		require $Internal_variables{cwd} . "/apf_main.pm";
		shopping_cart();
	} elsif ($FORM{go} eq "amazon") {
		print "Location:$Internal_variables{amazon_url}\n\n";
		exit;
	} else {
		my $xml_result;
		if ($FORM{Operation}) {
			my $this_xml_url = $Internal_variables{base_url} . "&Operation=$FORM{Operation}" . $Internal_variables{query};
			$xml_result = get_url($this_xml_url);
		}
		require $Internal_variables{cwd} . "/apf_main.pm";
		build_products__main($xml_result);
	}
}

sub url_encode {
	my $value = shift;
$debug .= qq[Before URL Encode: <code>$value</code><br />\n];
#	$value =~ s|\.||g; # Remove periods
	$value =~ s|/| |g;
	$value =~ s/([^A-Za-z0-9_])/sprintf("%%%02X", ord($1))/seg;
$debug .= qq[After URL Encode: <code>$value</code><br />\n];
	return $value;
}

sub html_escape {
	my $value = shift;
	if (!$load_entities_error) {
		$value = decode_entities($value);
		$value = encode_entities($value,'!"%()*\/<=>?[\\]^{|}\'&');
	} else {
  	study($value);
  	$value =~ s|\!|&#33;|g;
  	$value =~ s|\"|&#34;|g;
  	$value =~ s|\%|&#37;|g;
  	$value =~ s|\(|&#40;|g;
  	$value =~ s|\)|&#41;|g;
  	$value =~ s|\*|&#42;|g;
  	$value =~ s|\/|&#47;|g;
  	$value =~ s|\<|&#60;|g;
  	$value =~ s|\=|&#61;|g;
  	$value =~ s|\>|&#62;|g;
  	$value =~ s|\?|&#63;|g;
  	$value =~ s|\[|&#91;|g;
  	$value =~ s|\\|&#92;|g;
  	$value =~ s|\]|&#93;|g;
  	$value =~ s|\^|&#94;|g;
  	$value =~ s|\{|&#123;|g;
  	$value =~ s/\|/&#124;/g;
  	$value =~ s|\}|&#125;|g;
	}
	return $value;
}

sub get_url {
	my ($value, $skip, $signed_value) = @_;
	$value =~ s/ /%20/g;
	$value =~ s/BrowseNode=([^%&]+)%3A([^&]+)/BrowseNode=$1:$2/;
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { $value = &{$sub_name}($value); }
	}
	$debug .= qq[<a href="$value" target="xml">XML Request</a><br />\n];
	my ($cache_age,$cache_expire,$cache_time,%xml_cache,$xml_result,$dbm_error);
	if ($FORM{ResponseGroup} =~ /Large|Medium|Offer|SellerListing/) {
		$cache_age = 3600;
	} else {
		$cache_age = 86400;
	}
	$cache_expire = time() - $cache_age; $cache_time = $value . "_time";
	if ($Internal_variables{use_cache} eq "Yes" and $Internal_variables{debug_state} ne "on") {
		eval 'use Fcntl'; $dbm_error = $@;
		eval 'use DB_File'; $dbm_error .= $@;
		if (!$dbm_error) {
			if (-s $Internal_variables{cache_file} > (7000 * $Internal_variables{cache_max_size})) { unlink $Internal_variables{cache_file}; }
			eval 'tie(%xml_cache,"DB_File",$Internal_variables{cache_file},O_RDONLY)'; $dbm_error = $@;
		}
	}
	if ($xml_cache{$value} and $xml_cache{$cache_time} > $cache_expire) {
		$xml_result = $xml_cache{$value};
		untie %xml_cache;
	} else {
		untie %xml_cache;
		require $Internal_variables{cwd} . "/simpleget.pl";
		# load request signing routine
		require $Internal_variables{cwd} . "/sign_request.pl";
		for (my $temp_i = 1; $temp_i <= 3; $temp_i++) {
			$signed_value = sign_request($value);
			$debug .= qq[<a href="$signed_value" target="xml">Signed XML Request</a><br />\n];
			$xml_result = get($signed_value);
			if (!$xml_result) {
				sleep 1;
			} else {
				$MY_variables{error_msg} = ""; last;
			}
		}
		if (!$load_entities_error) {
			$xml_result = decode_entities($xml_result);
		} else {
  		study($xml_result);
  		$xml_result =~ s/&lt;/</gi;
  		$xml_result =~ s/&gt;/>/gi;
  		$xml_result =~ s/&amp;([^\s])/&$1/gi;
  		$xml_result =~ s/&amp;amp;quot;/&quot;/gi;
  		$xml_result =~ s/&amp;(.{2,5};)/&$1/gi;
  		$xml_result =~ s/<(\/?)i>/<$1em>/gi;
  		$xml_result =~ s/<(\/?)b>/<$1strong>/gi;
		}
		$xml_result =~ s/<a href=[^>]+>|<\/a>//gi;
		$xml_result =~ s/<p>(?=\s*<p>)//gi;
		$xml_result =~ s/(<table[^>]+)<tr=.<tr.>/$1><tr>/gi;
		$xml_result =~ s/(<tr[^>]*>)[^<]+<p>[^<]+(<td[^>]*>)/$1$2/gi;
		$xml_result =~ s/(<table[^>]*>)[^<]+<p>[^<]+(<tr[^>]*>)/$1$2/gi;
		$xml_result =~ s/<\/?p>/<br \/><br \/>/gi;
		$xml_result =~ s/<br>/<br \/>/gi;
		$xml_result =~ s/<[\/]*body>|<[\/]*html>|<\!DOCTYP[^>]+>//gi;
		if (!$xml_result and $skip ne "skip_ok") { $MY_variables{error_msg} = qq[Sorry, we are currently unable to process your request in a timely manner. <a href="$MY_variables{script_name}?go=amazon&amp;locale=$MY_variables{current_locale}">Please try $Internal_variables{amazon_wwwsite}</a>\n]; }
		if ($Internal_variables{use_cache} eq "Yes" and $Internal_variables{debug_state} ne "on" and !$dbm_error) {
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
		untie %xml_cache;
		close(LOCK);
	}
	$xml_result =~ s/<Message>([^<]+)<\/Message><\/Error>/if ($skip ne "skip_ok" and $FORM{SearchIndex} ne "Blended") { $MY_variables{error_msg} .= "Error: $1"; }/esi;

	return $xml_result;
}

