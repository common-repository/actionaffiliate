#!/usr/bin/perl
#
#	apf_config.cgi
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

use strict vars;

our (%AWS_variables,%MY_variables,%Internal_variables,%mod_use);
use vars qw(%associate_ids %MY_variables %Internal_variables %mod_use); 
use vars qw(@associate_ids_us @associate_ids_uk @associate_ids_de @associate_ids_jp @associate_ids_fr @associate_ids_ca @mod_files);
use vars qw(%time_zones %adult_browsenodes);
use vars qw(@time_zones_us @time_zones_uk @time_zones_de @time_zones_jp @time_zones_fr @time_zones_ca);
use vars qw($std_tzname_us $dst_tzname_us $date1_us $date2_us $date3_us);
use vars qw($std_tzname_uk $dst_tzname_uk $date1_uk $date2_uk $date3_uk);
use vars qw($std_tzname_de $dst_tzname_de $date1_de $date2_de $date3_de);
use vars qw($std_tzname_jp $dst_tzname_jp $date1_jp $date2_jp $date3_jp);
use vars qw($std_tzname_fr $dst_tzname_fr $date1_fr $date2_fr $date3_fr);
use vars qw($std_tzname_ca $dst_tzname_ca $date1_ca $date2_ca $date3_ca);

my (%FORM);
my ($html, $temp_list, $password_flag, $mods_html, $input_password, $flag);
my %ass_defaults = ( us => "httprockbotto-20", uk => "mrratcom-21", de => "absolutefreeb-21", jp => "mrratcom0f-22", fr => "mrratcom0d-21", ca => "mrratcom08-20" );
my %ass_locales = ( us => "associate_ids_us", uk => "associate_ids_uk", de => "associate_ids_de", jp => "associate_ids_jp", fr => "associate_ids_fr", ca => "associate_ids_ca" );
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
my $config_file = $Internal_variables{cwd} . "/apf_config.ini";
my $default_config_file = $Internal_variables{cwd} . "/apf_default_config.ini";
my $dont_generate = "no";
$Internal_variables{stored_password} = "";
$ENV{'HTTP_COOKIE'} =~ s/apfconfig=([^;]+)/$Internal_variables{stored_password} = $1/e;

$html = qq[
<html><head>
<style size="26" type"text/css">
<!--
.td1 { background-color:#FFCC68; }
.td2 { background-color:#00659C; }
-->
</style>
</head><body>
<h1 style="text-align:center;">APF Config</h1>
];

parse_form_data();

if (!-s $config_file) {
	if ($FORM{password}) {
		print "Set-Cookie: apfconfig=$input_password;\n";
		load_default_settings();
		write_config_file();
		$mods_html = load_mod_names();
	} else {
		init_password();
	}
} elsif (!$Internal_variables{stored_password}) {
	if ($FORM{password}) {
		require $config_file;
		@associate_ids_us = @{$associate_ids{us}};
		@associate_ids_uk = @{$associate_ids{uk}};
		@associate_ids_de = @{$associate_ids{de}};
		@associate_ids_jp = @{$associate_ids{jp}};
		@associate_ids_fr = @{$associate_ids{fr}};
		@associate_ids_ca = @{$associate_ids{ca}};

		@time_zones_us = @{$time_zones{us}};
		@time_zones_uk = @{$time_zones{uk}};
		@time_zones_de = @{$time_zones{de}};
		@time_zones_jp = @{$time_zones{jp}};
		@time_zones_fr = @{$time_zones{fr}};
		@time_zones_ca = @{$time_zones{ca}};

		$mods_html = load_mod_names();
		if ($Internal_variables{AWS_Keys_File_Name} ne '') {
			require $Internal_variables{AWS_Keys_File_Path} . '/' . $Internal_variables{AWS_Keys_File_Name};
		}
		verify_password();
		if ($password_flag eq "passed") {
			print "Set-Cookie: apfconfig=$Internal_variables{stored_password};\n";
		} else {
			login();
		}
	} else {
		login();
	}
} elsif ($FORM{load_defaults}) {
	load_default_settings();
	$mods_html = load_mod_names();
} elsif ($FORM{save_changes}) {
	$mods_html = load_mod_names();
	verify_password();
	if ($password_flag eq "passed") { write_config_file(); }
} else {
	require $config_file;
	@associate_ids_us = @{$associate_ids{us}};
	@associate_ids_uk = @{$associate_ids{uk}};
	@associate_ids_de = @{$associate_ids{de}};
	@associate_ids_jp = @{$associate_ids{jp}};
	@associate_ids_fr = @{$associate_ids{fr}};
	@associate_ids_ca = @{$associate_ids{ca}};

	@time_zones_us = @{$time_zones{us}};
	@time_zones_uk = @{$time_zones{uk}};
	@time_zones_de = @{$time_zones{de}};
	@time_zones_jp = @{$time_zones{jp}};
	@time_zones_fr = @{$time_zones{fr}};
	@time_zones_ca = @{$time_zones{ca}};

	$mods_html = load_mod_names();
	if ($Internal_variables{AWS_Keys_File_Name} ne '') {
		require $Internal_variables{AWS_Keys_File_Path} . '/' . $Internal_variables{AWS_Keys_File_Name};
	}

}

if (${$ass_locales{$MY_variables{default_locale}}}[0] eq $ass_defaults{$MY_variables{default_locale}}) {$flag = "background-color:#FF6666;"; }
if ($dont_generate eq "no") { generate_page(); }
print "Content-type: text/html; charset=utf-8\n\n";
print $html;

sub parse_form_data {
	my $query;
	read(STDIN, $query, $ENV{CONTENT_LENGTH}) == $ENV{CONTENT_LENGTH};
	for my $form_pair (split(/&/, $query)) {
		$form_pair =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$form_pair =~ s/[\&|\;|\`|\\|\"|\||\?|\~|\<|\>|\^|\[|\]|\{|\}|\$]/ /g;
		(my $form_name, my $form_value) = split(/=/, $form_pair);
		if ($form_name eq $form_value) { $form_value = ""; }
		$FORM{$form_name} = $form_value;
	}
	$MY_variables{AWSAccessKey} = $FORM{aws_access_key};
	$MY_variables{AWSSecretKey} = $FORM{aws_secret_key};
	@associate_ids_us = split(/\+/, $FORM{associate_ids_us});
	@associate_ids_uk = split(/\+/, $FORM{associate_ids_uk});
	@associate_ids_de = split(/\+/, $FORM{associate_ids_de});
	@associate_ids_jp = split(/\+/, $FORM{associate_ids_jp});
	@associate_ids_fr = split(/\+/, $FORM{associate_ids_fr});
	@associate_ids_ca = split(/\+/, $FORM{associate_ids_ca});

	@time_zones_us = ($FORM{std_tzname_us} , $FORM{dst_tzname_us}, $FORM{utc_tzdiff_us}, $FORM{date1_us}, $FORM{date2_us}, $FORM{date3_us});
	@time_zones_uk = ($FORM{std_tzname_uk} , $FORM{dst_tzname_uk}, $FORM{utc_tzdiff_uk}, $FORM{date1_uk}, $FORM{date2_uk}, $FORM{date3_uk});
	@time_zones_de = ($FORM{std_tzname_de} , $FORM{dst_tzname_de}, $FORM{utc_tzdiff_de}, $FORM{date1_de}, $FORM{date2_de}, $FORM{date3_de});
	@time_zones_jp = ($FORM{std_tzname_jp} , $FORM{dst_tzname_jp}, $FORM{utc_tzdiff_jp}, $FORM{date1_jp}, $FORM{date2_jp}, $FORM{date3_jp});
	@time_zones_fr = ($FORM{std_tzname_fr} , $FORM{dst_tzname_fr}, $FORM{utc_tzdiff_fr}, $FORM{date1_fr}, $FORM{date2_fr}, $FORM{date3_fr});
	@time_zones_ca = ($FORM{std_tzname_ca} , $FORM{dst_tzname_ca}, $FORM{utc_tzdiff_ca}, $FORM{date1_ca}, $FORM{date2_ca}, $FORM{date3_ca});

	$adult_browsenodes{us} = $FORM{adult_browsenodes_us};
	$adult_browsenodes{uk} = $FORM{adult_browsenodes_uk};
	$adult_browsenodes{de} = $FORM{adult_browsenodes_de};
	$adult_browsenodes{jp} = $FORM{adult_browsenodes_jp};
	$adult_browsenodes{fr} = $FORM{adult_browsenodes_fr};
	$adult_browsenodes{ca} = $FORM{adult_browsenodes_ca};

	$MY_variables{default_locale} = $FORM{default_locale};
	$Internal_variables{review_length} = $FORM{review_length};
	$Internal_variables{review_results_per_item_page} = $FORM{review_results_per_item_page};
	$Internal_variables{time_stamp_per_item} = $FORM{time_stamp_per_item};
	$Internal_variables{display_adult} = $FORM{display_adult};
	$Internal_variables{nodes_to_use_ca} = $FORM{nodes_to_use_ca};
	$Internal_variables{nodes_to_use_de} = $FORM{nodes_to_use_de};
	$Internal_variables{nodes_to_use_fr} = $FORM{nodes_to_use_fr};
	$Internal_variables{nodes_to_use_jp} = $FORM{nodes_to_use_jp};
	$Internal_variables{nodes_to_use_uk} = $FORM{nodes_to_use_uk};
	$Internal_variables{nodes_to_use_us} = $FORM{nodes_to_use_us};
	$Internal_variables{bad_nodes} = $FORM{bad_nodes};
	$Internal_variables{use_cache} = $FORM{use_cache};
	$Internal_variables{cache_file} = $FORM{cache_file};
	$Internal_variables{cache_max_size} = $FORM{cache_max_size};
	$Internal_variables{ResponseGroup_Products} = $FORM{ResponseGroup_Products};
	$Internal_variables{ResponseGroup_Item} = $FORM{ResponseGroup_Item};
	$Internal_variables{ResponseGroup_Reviews} = $FORM{ResponseGroup_Reviews};
	$Internal_variables{ResponseGroup_Image} = $FORM{ResponseGroup_Image};
	$Internal_variables{languages_directory} = $FORM{languages_directory};
	$Internal_variables{templates_directory} = $FORM{templates_directory};
	$Internal_variables{mods_directory} = $FORM{mods_directory};
	$Internal_variables{locale_directory} = $FORM{locale_directory};
	$Internal_variables{AWS_Keys_File_Path} = $FORM{aws_keys_file_path};
	$Internal_variables{AWS_Keys_File_Name} = $FORM{aws_keys_file_name};
	$input_password = crypt($FORM{password}, $FORM{password});
}

sub load_default_settings {
	require $default_config_file;
	@associate_ids_us = @{$associate_ids{us}};
	@associate_ids_uk = @{$associate_ids{uk}};
	@associate_ids_de = @{$associate_ids{de}};
	@associate_ids_jp = @{$associate_ids{jp}};
	@associate_ids_fr = @{$associate_ids{fr}};
	@associate_ids_ca = @{$associate_ids{ca}};

	@time_zones_us = @{$time_zones{us}};
	@time_zones_uk = @{$time_zones{uk}};
	@time_zones_de = @{$time_zones{de}};
	@time_zones_jp = @{$time_zones{jp}};
	@time_zones_fr = @{$time_zones{fr}};
	@time_zones_ca = @{$time_zones{ca}};

	$mods_html = load_mod_names();
}

sub load_mod_names {
	my $temp_html;
	opendir(DIR, $Internal_variables{mods_directory});
	@mod_files = grep { /\.mod$/ } readdir(DIR);
	closedir(DIR);
	foreach my $item (@mod_files) {
		$item =~ s/.mod//i;
		if ($FORM{$item} eq "Yes" or $mod_use{$item} eq "Yes") {
			$temp_html .= qq[<tr><td colspan="6" class="td1">$item</td><td colspan="2" class="td2"><div style="background-color:#FFFFFF;"><span style="text-align:center;width:49%;"><input name="$item" type="radio" value="Yes" checked>Yes</input></span><span style="text-align:center;width:49%;"><input name="$item" type="radio" value="No">No</input></span></div></td></tr>\n];
		} else {
			$temp_html .= qq[<tr><td colspan="6" class="td1">$item</td><td colspan="2" class="td2"><div style="background-color:#FFFFFF;"><span style="text-align:center;width:49%;"><input name="$item" type="radio" value="Yes">Yes</input></span><span style="text-align:center;width:49%;"><input name="$item" type="radio" value="No" checked>No</input></span></div></td></tr>\n];
		}
	}
	return $temp_html;
}

sub init_password {
	$html .= qq[
<form method="post"><table cellpadding="4" cellspacing="2" width="100%">
<tr><td colspan="2"><h3>No Configuration File Found</h3></td></tr>
<tr><td class="td1">Please enter a password to be used for all future configuration changes</td><td class="td2"><input name="password" size="26" type="password" /></td></tr>
<tr><td><br /></td><td></td></tr>
<tr><td><input style="background-color:#00CC66; cursor:hand; font-weight:bold;" type="submit" value="Save Password"></td></tr>
<tr><td><br /></td><td></td></tr>
<tr><td><br /></td><td></td></tr>
<tr><td class="td1" colspan="2">If you are unable to get this script to save your configuration file you can <a href="http://www.mrrat.com/cgi-bin/online_apf_config.cgi"><b>use the online version to download</b></a> a config file so that you can upload it to your server.</td></tr>
</table></form>
</body></html>
];
	print "Content-type: text/html; charset=utf-8\n\n";
	print $html;
	exit;
}

sub login {
	$html .= qq[
<form method="post"><table cellpadding="4" cellspacing="2" width="100%">
<tr><td colspan="2"><h3>Log In</h3></td></tr>
<tr><td class="td1">Please enter the configuration password</td><td class="td2"><input name="password" size="26" type="password" /></td></tr>
<tr><td><br /></td><td></td></tr>
<tr><td><input style="background-color:#00CC66; cursor:hand; font-weight:bold;" type="submit" value="Save Password"></td></tr>
</table></form>
</body></html>
];
	print "Content-type: text/html; charset=utf-8\n\n";
	print $html;
	exit;
}

sub verify_password {
	if ($input_password eq $Internal_variables{stored_password}) {
		$password_flag = "passed";
	} else {
		$html .= qq[<h2 style="background-color:#FF6666;">Invalid Password</h2>];
	}
}

sub write_config_file {

	my $warning_flag = 0; # Warning Flag for use in final output

	# Set default AWS_Keys_File_Path if it is left blank
	if ( $Internal_variables{AWS_Keys_File_Path} eq '' ) {
		$html .= qq[sub write_config_file: Blank Path<br />];
		$html .= qq[Path found: $Internal_variables{AWS_Keys_File_Path}<br />];
		$Internal_variables{AWS_Keys_File_Path} = $Internal_variables{cwd};
		$warning_flag += 1;
	};
	# Set default AWS_Keys_File_Name if it is left blank
	if ( $Internal_variables{AWS_Keys_File_Name} eq '' ) {
		$html .= qq[sub write_config_file: Blank Name<br />];
		$html .= qq[Path found: $Internal_variables{AWS_Keys_File_Name}<br />];
		$Internal_variables{AWS_Keys_File_Name} = 'apf4_AWS_KEYS.ini';
		$warning_flag += 2;
	};

	my $config = qq[
\$Internal_variables{stored_password} = "$input_password";
\$associate_ids{us} = [ qw(@associate_ids_us) ];
\$associate_ids{uk} = [ qw(@associate_ids_uk) ];
\$associate_ids{de} = [ qw(@associate_ids_de) ];
\$associate_ids{jp} = [ qw(@associate_ids_jp) ];
\$associate_ids{fr} = [ qw(@associate_ids_fr) ];
\$associate_ids{ca} = [ qw(@associate_ids_ca) ];
# Time Zones as Standard Time, Daylight Savings Time, UTC Offset, Date format
\$time_zones{us} = [ qw(@time_zones_us) ];
\$time_zones{uk} = [ qw(@time_zones_uk) ];
\$time_zones{de} = [ qw(@time_zones_de) ];
\$time_zones{jp} = [ qw(@time_zones_jp) ];
\$time_zones{fr} = [ qw(@time_zones_fr) ];
\$time_zones{ca} = [ qw(@time_zones_ca) ];
# Basic Options
\$MY_variables{default_locale} = "$MY_variables{default_locale}";
\$Internal_variables{review_length} = "$Internal_variables{review_length}";
\$Internal_variables{review_results_per_item_page} = "$Internal_variables{review_results_per_item_page}";
\$Internal_variables{time_stamp_per_item} = "$Internal_variables{time_stamp_per_item}";
# Adult content
\$Internal_variables{display_adult} = "$Internal_variables{display_adult}";
\$adult_browsenodes{us} = "$adult_browsenodes{us}";
\$adult_browsenodes{uk} = "$adult_browsenodes{uk}";
\$adult_browsenodes{de} = "$adult_browsenodes{de}";
\$adult_browsenodes{jp} = "$adult_browsenodes{jp}";
\$adult_browsenodes{fr} = "$adult_browsenodes{fr}";
\$adult_browsenodes{ca} = "$adult_browsenodes{ca}";
\$Internal_variables{nodes_to_use_ca} = "$Internal_variables{nodes_to_use_ca}";
\$Internal_variables{nodes_to_use_de} = "$Internal_variables{nodes_to_use_de}";
\$Internal_variables{nodes_to_use_fr} = "$Internal_variables{nodes_to_use_fr}";
\$Internal_variables{nodes_to_use_jp} = "$Internal_variables{nodes_to_use_jp}";
\$Internal_variables{nodes_to_use_uk} = "$Internal_variables{nodes_to_use_uk}";
\$Internal_variables{nodes_to_use_us} = "$Internal_variables{nodes_to_use_us}";
\$Internal_variables{bad_nodes} = "$Internal_variables{bad_nodes},";
\$Internal_variables{use_cache} = "$Internal_variables{use_cache}";
\$Internal_variables{cache_file} = "$Internal_variables{cache_file}";
\$Internal_variables{cache_max_size} = "$Internal_variables{cache_max_size}";
\$Internal_variables{ResponseGroup_Products} = "$Internal_variables{ResponseGroup_Products}";
\$Internal_variables{ResponseGroup_Item} = "$Internal_variables{ResponseGroup_Item}";
\$Internal_variables{ResponseGroup_Reviews} = "$Internal_variables{ResponseGroup_Reviews}";
\$Internal_variables{ResponseGroup_Image} = "$Internal_variables{ResponseGroup_Image}";
\$Internal_variables{mods_directory} = "$Internal_variables{mods_directory}";
\$Internal_variables{languages_directory} = "$Internal_variables{languages_directory}";
\$Internal_variables{templates_directory} = "$Internal_variables{templates_directory}";
\$Internal_variables{locale_directory} = "$Internal_variables{locale_directory}";
\$Internal_variables{AWS_Keys_File_Path} = "$Internal_variables{AWS_Keys_File_Path}";
\$Internal_variables{AWS_Keys_File_Name} = "$Internal_variables{AWS_Keys_File_Name}";
\@mod_files = qw(@mod_files);
];
	foreach my $item (@mod_files) {
		$config .= qq[\$mod_use{$item} = "$FORM{$item}";\n];
	}
	$config .= qq[\n1;\n];
	unless (open (FILE, ">$config_file")) {
		$html .= qq[<h2 style="background-color:#CC0000; color:#FFFFFF">ERROR!</h2>Unable to write to configuration file '$config_file' !<br /><br />];
	}else{
		print FILE $config;
		close (FILE);
		$html .= qq[<h2 style="background-color:#00CC66;">Configuration Saved</h2>];
	}

	my $aws_config = qq[
\$MY_variables{AWSAccessKey} = "$MY_variables{AWSAccessKey}";
\$MY_variables{AWSSecretKey} = "$MY_variables{AWSSecretKey}";
];
	$aws_config .= qq[\n1;\n];
	unless (open (FILE, ">$Internal_variables{AWS_Keys_File_Path}/$Internal_variables{AWS_Keys_File_Name}")) {
		# Display a warning message if default path/name used
		if ($warning_flag == 3) { # Defaults used for AWS_Keys_File_Path *_AND_* Blank AWS_Keys_File_Name
			$html .= qq[<h2 style="background-color:#FF8800;">WARNING Defaults used for AWS Keys File Path and Name</h2>];
		}elsif ($warning_flag == 1) { # Default used for AWS_Keys_File_Path
			$html .= qq[<h2 style="background-color:#FF8800;">WARNING Default used for AWS Keys File Path</h2>];
		}elsif ($warning_flag == 2) { # Default used for AWS_Keys_File_Name
			$html .= qq[<h2 style="background-color:#FF8800;">WARNING Default used for AWS Keys File Name</h2>];
		}
		$html .= qq[<h2 style="background-color:#CC0000; color:#FFFFFF">ERROR!</h2>Unable to write to AWS Keys file '$Internal_variables{AWS_Keys_File_Path}/$Internal_variables{AWS_Keys_File_Name}' !<br /><br />];
	}else{
		print FILE $aws_config;
		close (FILE);

		# Display a success or warning message
		if ($warning_flag == 3) { # Defaults used for AWS_Keys_File_Path *_AND_* Blank AWS_Keys_File_Name
			$html .= qq[<h2 style="background-color:#FF8800;">WARNING Defaults used for AWS Keys File Path and Name</h2>];
		}elsif ($warning_flag == 1) { # Default used for AWS_Keys_File_Path
			$html .= qq[<h2 style="background-color:#FF8800;">WARNING Default used for AWS Keys File Path</h2>];
		}elsif ($warning_flag == 2) { # Default used for AWS_Keys_File_Name
			$html .= qq[<h2 style="background-color:#FF8800;">WARNING Default used for AWS Keys File Name</h2>];
		}
		$html .= qq[<h2 style="background-color:#00CC66;">AWS Configuration Saved</h2>];
	}
}

sub generate_page {
	my $use_cache_html = qq[<tr><td colspan="6" class="td1">Use cache file</td><td colspan="2" class="td2"><div style="background-color:#FFFFFF;"><span style="text-align:center;width:49%;"><input name="use_cache" type="radio" value="Yes"];
	if ($Internal_variables{use_cache} eq "No") {
		$use_cache_html .= qq[>Yes</input></span><span style="text-align:center;width:49%;"><input name="use_cache" type="radio" value="No" checked>No</input></span></div></td></tr>\n];
	} else {
		$use_cache_html .= qq[ checked>Yes</input></span><span style="text-align:center;width:49%;"><input name="use_cache" type="radio" value="No">No</input></span></div></td></tr>\n];
	}
	my $display_adult_html = qq[
<tr><td colspan="8" ><br /></td></tr>
<tr><td colspan="8">Adult Content</td></tr>
<tr><td colspan="6" class="td1">Display Adult Products</td><td colspan="2" class="td2"><div style="background-color:#FFFFFF;"><span style="text-align:center;width:49%;"><input name="display_adult" type="radio" value="Yes"];
	if ($Internal_variables{display_adult} ne "Yes") {
		$display_adult_html .= qq[>Yes</input></span><span style="text-align:center;width:49%;"><input name="display_adult" type="radio" value="No" checked>No</input></span></div></td></tr>\n];
	} else {
		$display_adult_html .= qq[ checked>Yes</input></span><span style="text-align:center;width:49%;"><input name="display_adult" type="radio" value="No">No</input></span></div></td></tr>\n];
	}
	$display_adult_html .= qq[
<tr><td colspan="8" style="$flag">Adult BrowseNodes (comma separated)</td></tr>
<tr><td colspan="6" class="td1">US</td><td colspan="2" class="td2"><input name="adult_browsenodes_us" size="26" type"text" value="$adult_browsenodes{us}" /></td></tr>
<tr><td colspan="6" class="td1">UK</td><td colspan="2" class="td2"><input name="adult_browsenodes_uk" size="26" type"text" value="$adult_browsenodes{uk}" /></td></tr>
<tr><td colspan="6" class="td1">DE</td><td colspan="2" class="td2"><input name="adult_browsenodes_de" size="26" type"text" value="$adult_browsenodes{de}" /></td></tr>
<tr><td colspan="6" class="td1">JP</td><td colspan="2" class="td2"><input name="adult_browsenodes_jp" size="26" type"text" value="$adult_browsenodes{jp}" /></td></tr>
<tr><td colspan="6" class="td1">FR</td><td colspan="2" class="td2"><input name="adult_browsenodes_fr" size="26" type"text" value="$adult_browsenodes{fr}" /></td></tr>
<tr><td colspan="6" class="td1">CA</td><td colspan="2" class="td2"><input name="adult_browsenodes_ca" size="26" type"text" value="$adult_browsenodes{ca}" /></td></tr>
];

	my $default_locale_html;
	$default_locale_html .= qq[<tr><td colspan="5" class="td1">Default locale</td><td colspan="3" class="td2"><div style="background-color:#FFFFFF;"><span style="text-align:center;width:33%;"><input name="default_locale" type="radio" value="ca"];
	if ($MY_variables{default_locale} eq "ca") { $default_locale_html .= qq[ checked]; }
	$default_locale_html .= qq[>ca</input></span><span style="text-align:center;width:33%;"><input name="default_locale" type="radio" value="de"];
	if ($MY_variables{default_locale} eq "de") { $default_locale_html .= qq[ checked]; }
	$default_locale_html .= qq[>de</input></span><span style="text-align:center;width:33%;"><input name="default_locale" type="radio" value="fr"];
	if ($MY_variables{default_locale} eq "fr") { $default_locale_html .= qq[ checked]; }
	$default_locale_html .= qq[>fr</input></span><span style="text-align:center;width:33%;"><input name="default_locale" type="radio" value="jp"];
	if ($MY_variables{default_locale} eq "jp") { $default_locale_html .= qq[ checked]; }
	$default_locale_html .= qq[>jp</input></span><span style="text-align:center;width:33%;"><input name="default_locale" type="radio" value="uk"];
	if ($MY_variables{default_locale} eq "uk") { $default_locale_html .= qq[ checked]; }
	$default_locale_html .= qq[>uk</input></span><span style="text-align:center;width:33%;"><input name="default_locale" type="radio" value="us"];
	if ($MY_variables{default_locale} eq "us") { $default_locale_html .= qq[ checked]; }
	$default_locale_html .= qq[>us</input></span>];
	$default_locale_html .= qq[</div></td></tr>\n];

	$html .= qq[
<form method="post"><table cellpadding="4" cellspacing="2" width="100%">
<tr><td colspan="7"><h3>Required Settings</h3></td></tr>
<tr><td colspan="8" style="$flag">File to store AWS keys in (for maximum security this should <b>NOT</b> be a directory served by your webserver)</td></tr>
<tr><td colspan="6" class="td1">Path to AWS Keys File (enter the full path)</td><td colspan="2" class="td2"><input name="aws_keys_file_path" size="26" type"text" value="$Internal_variables{AWS_Keys_File_Path}" /></td></tr>
<tr><td colspan="6" class="td1">Name of AWS Keys File (enter the file name)</td><td colspan="2" class="td2"><input name="aws_keys_file_name" size="26" type"text" value="$Internal_variables{AWS_Keys_File_Name}" /></td></tr>
<tr><td colspan="8" ><br /></td></tr>
<tr><td colspan="8" style="$flag">Amazon Web Services Keys (you must enter both your access key, and your secret key)</td></tr>
<tr><td colspan="6" class="td1">AWS Access Key</td><td colspan="2" class="td2"><input name="aws_access_key" size="26" type"text" value="$MY_variables{AWSAccessKey}" /></td></tr>
<tr><td colspan="6" class="td1">AWS Secret Key</td><td colspan="2" class="td2"><input name="aws_secret_key" size="26" type"text" value="$MY_variables{AWSSecretKey}" /></td></tr>
<tr><td colspan="7" ><br /></td></tr>
<tr><td colspan="8" style="$flag">Associate IDs (you must at least enter an ID for the default locale. multiple IDs can be separated by spaces)</td></tr>
<tr><td colspan="6" class="td1">US</td><td colspan="2" class="td2"><input name="associate_ids_us" size="26" type"text" value="@associate_ids_us" /></td></tr>
<tr><td colspan="6" class="td1">UK</td><td colspan="2" class="td2"><input name="associate_ids_uk" size="26" type"text" value="@associate_ids_uk" /></td></tr>
<tr><td colspan="6" class="td1">DE</td><td colspan="2" class="td2"><input name="associate_ids_de" size="26" type"text" value="@associate_ids_de" /></td></tr>
<tr><td colspan="6" class="td1">JP</td><td colspan="2" class="td2"><input name="associate_ids_jp" size="26" type"text" value="@associate_ids_jp" /></td></tr>
<tr><td colspan="6" class="td1">FR</td><td colspan="2" class="td2"><input name="associate_ids_fr" size="26" type"text" value="@associate_ids_fr" /></td></tr>
<tr><td colspan="6" class="td1">CA</td><td colspan="2" class="td2"><input name="associate_ids_ca" size="26" type"text" value="@associate_ids_ca" /></td></tr>
<tr><td colspan="7" ><br /></td></tr>

<tr><td colspan="2 style="$flag">Time Zone Abbreviations (you must at least enter Time Zone Abbreviations for the default locale.)</td><td>Standard Time</td><td>Daylight Savings Time</td><td>Difference from UTC</td><td colspan="3">Date Format</td></tr>
<tr><td colspan="2" class="td1">US</td><td class="td2"><input name="std_tzname_us" size="6" type"text" value="$time_zones_us[0]" /></td><td class="td2"><input name="dst_tzname_us" size="6" type"text" value="$time_zones_us[1]" /></td><td class="td2"><input name="utc_tzdiff_us" size="3" type"text" value="$time_zones_us[2]" /></td>
<td class="td2"><select name="date1_us"><option value="d"];
	if ($time_zones_us[3] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_us[3] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_us[3] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date2_us"><option value="d"
];
	if ($time_zones_us[4] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_us[4] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_us[4] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date3_us"><option value="d"
];
	if ($time_zones_us[5] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_us[5] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_us[5] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td></tr>
<tr><td colspan="2" class="td1">UK</td><td class="td2"><input name="std_tzname_uk" size="6" type"text" value="$time_zones_uk[0]" /></td><td class="td2"><input name="dst_tzname_uk" size="6" type"text" value="$time_zones_uk[1]" /></td><td class="td2"><input name="utc_tzdiff_uk" size="3" type"text" value="$time_zones_uk[2]" /></td>
<td class="td2"><select name="date1_uk"><option value="d"];
	if ($time_zones_uk[3] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_uk[3] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_uk[3] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date2_uk"><option value="d"
];
	if ($time_zones_uk[4] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_uk[4] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_uk[4] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date3_uk"><option value="d"
];
	if ($time_zones_uk[5] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_uk[5] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_uk[5] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td></tr>
<tr><td colspan="2" class="td1">DE</td><td class="td2"><input name="std_tzname_de" size="6" type"text" value="$time_zones_de[0]" /></td><td class="td2"><input name="dst_tzname_de" size="6" type"text" value="$time_zones_de[1]" /></td><td class="td2"><input name="utc_tzdiff_de" size="3" type"text" value="$time_zones_de[2]" /></td>
<td class="td2"><select name="date1_de"><option value="d"];
	if ($time_zones_de[3] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_de[3] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_de[3] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date2_de"><option value="d"
];
	if ($time_zones_de[4] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_de[4] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_de[4] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date3_de"><option value="d"
];
	if ($time_zones_de[5] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_de[5] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_de[5] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td></tr>
<tr><td colspan="2" class="td1">JP</td><td class="td2"><input name="std_tzname_jp" size="6" type"text" value="$time_zones_jp[0]" /></td><td class="td2"><input name="dst_tzname_jp" size="6" type"text" value="$time_zones_jp[1]" /></td><td class="td2"><input name="utc_tzdiff_jp" size="3" type"text" value="$time_zones_jp[2]" /></td>
<td class="td2"><select name="date1_jp"><option value="d"];
	if ($time_zones_jp[3] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_jp[3] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_jp[3] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date2_jp"><option value="d"
];
	if ($time_zones_jp[4] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_jp[4] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_jp[4] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date3_jp"><option value="d"
];
	if ($time_zones_jp[5] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_jp[5] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_jp[5] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td></tr>
<tr><td colspan="2" class="td1">FR</td><td class="td2"><input name="std_tzname_fr" size="6" type"text" value="$time_zones_fr[0]" /></td><td class="td2"><input name="dst_tzname_fr" size="6" type"text" value="$time_zones_fr[1]" /></td><td class="td2"><input name="utc_tzdiff_fr" size="3" type"text" value="$time_zones_fr[2]" /></td>
<td class="td2"><select name="date1_fr"><option value="d"];
	if ($time_zones_fr[3] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_fr[3] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_fr[3] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date2_fr"><option value="d"
];
	if ($time_zones_fr[4] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_fr[4] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_fr[4] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date3_fr"><option value="d"
];
	if ($time_zones_fr[5] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_fr[5] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_fr[5] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td></tr>
<tr><td colspan="2" class="td1">CA</td><td class="td2"><input name="std_tzname_ca" size="6" type"text" value="$time_zones_ca[0]" /></td><td class="td2"><input name="dst_tzname_ca" size="6" type"text" value="$time_zones_ca[1]" /></td><td class="td2"><input name="utc_tzdiff_ca" size="3" type"text" value="$time_zones_ca[2]" /></td>
<td class="td2"><select name="date1_ca"><option value="d"];
	if ($time_zones_ca[3] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_ca[3] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_ca[3] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date2_ca"><option value="d"
];
	if ($time_zones_ca[4] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_ca[4] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_ca[4] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td>
<td class="td2"><select name="date3_ca"><option value="d"
];
	if ($time_zones_ca[5] eq 'd') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Day</option><option value="m"];
	if ($time_zones_ca[5] eq 'm') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Month</option><option value="y"];
	if ($time_zones_ca[5] eq 'y') {
		$html .= qq[ selected="selected"];
	}
	$html .= qq[>Year</option></select></td></tr>
<tr><td colspan="8" ><br /></td></tr>
<tr><td colspan="8" ><br /></td></tr>

<tr><td colspan="8"><h3>Basic Options</h3></td></tr>
$default_locale_html
<tr><td colspan="5" class="td1">Maximum number of characters of each review to display on Item page</td><td colspan="3" class="td2"><input name="review_length" size="26" type"text" value="$Internal_variables{review_length}" /></td></tr>
<tr><td colspan="5" class="td1">Maximum number of reviews to display on Item page (5 maximum)</td><td colspan="3" class="td2"><input name="review_results_per_item_page" size="26" type"text" value="$Internal_variables{review_results_per_item_page}" /></td></tr>


<tr><td colspan="5" class="td1">Display Time Stamp per Item</td><td colspan="3" class="td2"><div style="background-color:#FFFFFF;"><span style="text-align:center;width:49%;"><input name="time_stamp_per_item" type="radio" value="Yes"];
	if ($Internal_variables{time_stamp_per_item} ne "Yes") {
		$html .= qq[>Yes</input></span><span style="text-align:center;width:49%;"><input name="time_stamp_per_item" type="radio" value="No" checked>No</input></span></div></td></tr>\n];
	} else {
		$html .= qq[ checked>Yes</input></span><span style="text-align:center;width:49%;"><input name="time_stamp_per_item" type="radio" value="No">No</input></span></div></td></tr>\n];
	}

$html .= qq[$display_adult_html
<tr><td colspan="8" ><br /></td></tr>

<tr><td colspan="8">Include/Exclude Items</td></tr>
<tr><td colspan="6" class="td1">List of BrowseNodes to exclude (comma separated)</td><td colspan="2" class="td2"><input name="bad_nodes" size="26" type"text" value="$Internal_variables{bad_nodes}" /></td></tr>
<tr><td colspan="6" class="td1">Limit <a href="http://docs.amazonwebservices.com/AWSEcommerceService/2006-06-28/ApiReference/SearchIndexValues.html" target="docs">CA SearchIndexes</a> to browse (comma separated and case sensitive)</td><td colspan="2" class="td2"><input name="nodes_to_use_ca" size="26" type"text" value="$Internal_variables{nodes_to_use_ca}" /></td></tr>
<tr><td colspan="6" class="td1">Limit <a href="http://docs.amazonwebservices.com/AWSEcommerceService/2006-06-28/ApiReference/SearchIndexValues.html" target="docs">DE SearchIndexes</a> to browse (comma separated and case sensitive)</td><td colspan="2" class="td2"><input name="nodes_to_use_de" size="26" type"text" value="$Internal_variables{nodes_to_use_de}" /></td></tr>
<tr><td colspan="6" class="td1">Limit <a href="http://docs.amazonwebservices.com/AWSEcommerceService/2006-06-28/ApiReference/SearchIndexValues.html" target="docs">FR SearchIndexes</a> to browse (comma separated and case sensitive)</td><td colspan="2" class="td2"><input name="nodes_to_use_fr" size="26" type"text" value="$Internal_variables{nodes_to_use_fr}" /></td></tr>
<tr><td colspan="6" class="td1">Limit <a href="http://docs.amazonwebservices.com/AWSEcommerceService/2006-06-28/ApiReference/SearchIndexValues.html" target="docs">JP SearchIndexes</a> to browse (comma separated and case sensitive)</td><td colspan="2" class="td2"><input name="nodes_to_use_jp" size="26" type"text" value="$Internal_variables{nodes_to_use_jp}" /></td></tr>
<tr><td colspan="6" class="td1">Limit <a href="http://docs.amazonwebservices.com/AWSEcommerceService/2006-06-28/ApiReference/SearchIndexValues.html" target="docs">UK SearchIndexes</a> to browse (comma separated and case sensitive)</td><td colspan="2" class="td2"><input name="nodes_to_use_uk" size="26" type"text" value="$Internal_variables{nodes_to_use_uk}" /></td></tr>
<tr><td colspan="6" class="td1">Limit <a href="http://docs.amazonwebservices.com/AWSEcommerceService/2006-06-28/ApiReference/SearchIndexValues.html" target="docs">US SearchIndexes</a> to browse (comma separated and case sensitive)</td><td colspan="2" class="td2"><input name="nodes_to_use_us" size="26" type"text" value="$Internal_variables{nodes_to_use_us}" /></td></tr>
<tr><td colspan="7" ><br /></td></tr>
<tr><td colspan="8" ><br /></td></tr>

<tr><td colspan="8"><h3>Advanced Options</h3></td></tr>
<tr><td colspan="8">Cache Settings</td></tr>
$use_cache_html
<tr><td colspan="6" class="td1">Name of file (you can include a full path here)</td><td colspan="2" class="td2"><input name="cache_file" size="26" type"text" value="$Internal_variables{cache_file}" /></td></tr>
<tr><td colspan="6" class="td1">Maximum number of results to cache</td><td colspan="2" class="td2"><input name="cache_max_size" size="26" type"text" value="$Internal_variables{cache_max_size}" /></td></tr>
<tr><td colspan="8" ><br /></td></tr>

<tr><td colspan="8"><a href="http://docs.amazonwebservices.com/AWSEcommerceService/2006-06-28/ApiReference/ResponseGroupsArticle.html" target="docs">Response Groups</a></td></tr>
<tr><td colspan="6" class="td1">Products</td><td colspan="2" class="td2"><input name="ResponseGroup_Products" size="26" type"text" value="$Internal_variables{ResponseGroup_Products}" /></td></tr>
<tr><td colspan="6" class="td1">Item</td><td colspan="2" class="td2"><input name="ResponseGroup_Item" size="26" type"text" value="$Internal_variables{ResponseGroup_Item}" /></td></tr>
<tr><td colspan="6" class="td1">Reviews</td><td colspan="2" class="td2"><input name="ResponseGroup_Reviews" size="26" type"text" value="$Internal_variables{ResponseGroup_Reviews}" /></td></tr>
<tr><td colspan="6" class="td1">Image</td><td colspan="2" class="td2"><input name="ResponseGroup_Image" size="26" type"text" value="$Internal_variables{ResponseGroup_Image}" /></td></tr>
<tr><td colspan="8" ><br /></td></tr>

<tr><td colspan="8">Directory Settings</td></tr>
<tr><td colspan="6" class="td1">Language files</td><td colspan="2" class="td2"><input name="languages_directory" size="26" type"text" value="$Internal_variables{languages_directory}" /></td></tr>
<tr><td colspan="6" class="td1">Locale files</td><td colspan="2" class="td2"><input name="locale_directory" size="26" type"text" value="$Internal_variables{locale_directory}" /></td></tr>
<tr><td colspan="6" class="td1">Templates</td><td colspan="2" class="td2"><input name="templates_directory" size="26" type"text" value="$Internal_variables{templates_directory}" /></td></tr>
<tr><td colspan="6" class="td1">Mods</td><td colspan="2" class="td2"><input name="mods_directory" size="26" type"text" value="$Internal_variables{mods_directory}" /></td></tr>
<tr><td colspan="8" ><br /></td></tr>

<tr><td colspan="8">Pick which of the following available mods you would like to use</td></tr>
$mods_html
<tr><td colspan="8" ><br /></td></tr>
<tr><td colspan="8" ><br /></td></tr>

<tr><td colspan="8"><h3>Save Changes</h3></td></tr>
<tr><td colspan="6" class="td1">Please enter a password to save changes</td><td colspan="2" class="td2"><input name="password" size="26" type="password" /></td></tr>
<tr><td colspan="8" ><br /></td></tr>

<tr><td><input name="save_changes" style="background-color:#00CC66; cursor:hand; font-weight:bold;" type="submit" value="Save Changes"></td></tr>
</table></form>
<br /><br /><form method="post"><input name="load_defaults" style="background-color:#FF6666;" type="submit" value="Load Program Defaults"></form></body></html>
];
}

