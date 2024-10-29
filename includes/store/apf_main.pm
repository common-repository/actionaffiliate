#	apf_main.pm
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

sub build_products__main {
	my $xml_result = shift;
	if ($FORM{Operation} eq "ItemSearch") {
		if ($Internal_variables{browse_header} and !$MY_variables{error_msg}) {	$MY_variables{products_html} .= "<br /><br />"; }
		my $level_1 = parse_xml_into_hashes_of_arrays($xml_result);
		if ($AWS_variables{TotalResults} eq 1) {
			${${$level_1}{Item}}[0] =~ /<ASIN>([^<]+)<\/ASIN>/;
			$FORM{ItemId} = "$1"; $FORM{Operation} = "ItemLookup"; $FORM{ResponseGroup} = $Internal_variables{ResponseGroup_Item};
			delete $MY_variables{header}; delete $MY_variables{SearchIndex}; delete $FORM{BrowseNode}; delete $FORM{Keywords};
			$debug .= "wait 1 second then get single product<br />\n";
			sleep 1;
			goto START_PROCESSING_LABEL;	# yes i know goto is lame, bite me
		} elsif ($FORM{SearchIndex} eq "Blended") {
			parse_blended($level_1);
		} else {
			if ($FORM{Keywords}) { ($MY_variables{subject} = $FORM{Keywords}) =~ s/\+/ /g; $MY_variables{store} = $language_text{button_text4}; $MY_variables{header} = qq[$MY_variables{store}: $MY_variables{subject}]; }
			assign_variables("products",$level_1);
		}
		if ($Internal_variables{browse_header}) {
			 $MY_variables{header} = $Internal_variables{browse_header};
		}
	} elsif ($FORM{Operation} eq "ItemLookup") {
		if ($FORM{ItemId} =~ /,/) {
			my $level_1 = parse_xml_into_hashes_of_arrays($xml_result);
			assign_variables("products",$level_1);
			$MY_variables{store} = $language_text{header_text2}; $MY_variables{subject} = $language_text{header_text3};
		} elsif ($FORM{myOperation} eq "CustomerReviews") {
			my $level_1 = parse_xml_into_hashes_of_arrays($xml_result);
			assign_variables("customer_reviews",$level_1);
			$MY_variables{store} = $lookup_store{$catalog_to_mode{$AWS_variables{ProductGroup}}}; $MY_variables{subject} = $AWS_variables{Title};
			$MY_variables{header} = qq[$MY_variables{store} : <a href="$MY_variables{item_url}">$MY_variables{subject}</a>];
		} elsif ($FORM{myOperation} eq "Image") {
			my $level_1 = parse_xml_into_hashes_of_arrays($xml_result);
			assign_variables("larger_image",$level_1);
			$MY_variables{store} = $lookup_store{$catalog_to_mode{$AWS_variables{ProductGroup}}}; $MY_variables{subject} = $AWS_variables{Title};
			$MY_variables{header} = qq[$MY_variables{store} : <a href="$MY_variables{item_url}" rel=lightbox>$MY_variables{subject}</a>];
		} else {
			my $level_1 = parse_xml_into_hashes_of_arrays($xml_result);
			assign_variables("item",$level_1);
			$MY_variables{store} = $lookup_store{$catalog_to_mode{$AWS_variables{ProductGroup}}}; $MY_variables{subject} = $AWS_variables{Title};
		}
		$MY_variables{header} = $AWS_variables{Title}; 
	} elsif ($FORM{Operation} eq "SimilarityLookup") {
		my $level_1 = parse_xml_into_hashes_of_arrays($xml_result);
		assign_variables("products",$level_1);
		$MY_variables{store} = $language_text{my_similar_products_text1}; $MY_variables{subject} = $language_text{button_text4}; $MY_variables{header} = qq[$MY_variables{store} $MY_variables{subject}];
	} elsif ($MY_variables{SearchIndex}) {
		$MY_variables{subject} = $language_text{header_text5};
		if (!$FORM{BrowseNode}) {
			$Internal_variables{nav_menu_type}  = "modes";
			if (!$current_base_nodes{$MY_variables{SearchIndex}}) {
				$Internal_variables{node_listing} = \%{$MY_variables{SearchIndex}};
			} else {
				$FORM{BrowseNode} = $current_base_nodes{$MY_variables{SearchIndex}};
				$Internal_variables{node_listing} = get_node_children($FORM{BrowseNode});
			}
#			$MY_variables{BrowseNodeName_display} = $language_text{header_text4};
		} else {
			$Internal_variables{nav_menu_type}  = "children";
			$Internal_variables{node_listing} = get_node_children($FORM{BrowseNode});
		}
#		$Internal_variables{browse_header} = qq[$Internal_variables{bestsellers_header}<a href="$MY_variables{script_name}?SearchIndex=$MY_variables{SearchIndex}$Internal_variables{url_options}">$MY_variables{store}</a> &gt; $MY_variables{BrowseNodeName_display}];
		$MY_variables{products_html} = load_browse_table($Internal_variables{node_listing}, "SearchIndex=$MY_variables{SearchIndex}&amp;BrowseNode=");
		$FORM{Operation} = "ItemSearch";
		$debug .= "wait 1 second then get products<br />\n";
		sleep 1;
		goto START_PROCESSING_LABEL;	# yes i know goto is lame, bite me
	} elsif ($FORM{Operation} eq "ListLookup") {
		$MY_variables{store} = $FORM{ListType};
		$xml_result =~ s/<ListItem>(<ListItemId>[^<]+<\/ListItemId>)(.*?)<Item>/<ListItem>$1$2<Item>$1/sg;
		my $level_1 = parse_xml_into_hashes_of_arrays($xml_result);
		if ($AWS_variables{TotalResults} eq 1) {
			${${$level_1}{Item}}[0] =~ /<ASIN>([^<]+)<\/ASIN>/;
			$FORM{ItemId} = "$1"; $FORM{Operation} = "ItemLookup"; $FORM{ResponseGroup} = $Internal_variables{ResponseGroup_Item} . ",ListItems";
			delete $MY_variables{header}; delete $MY_variables{SearchIndex}; delete $FORM{BrowseNode}; delete $FORM{Keywords};
			$debug .= "wait 1 second then get single product<br />\n";
			sleep 1;
			goto START_PROCESSING_LABEL;	# yes i know goto is lame, bite me
		} else {
			$xml_result =~ s/<TotalPages>(\d+)<\/TotalPages>/$AWS_variables{TotalPages} = $1/e;
			my $level_2 = process_hashes_of_arrays(\%$level_1);
			my $level_3 = process_hashes_of_arrays(\%$level_2);
			assign_variables("products",$level_3);
		}
	} else {
		(my $this_function = (caller(0))[3]) =~ s/[^:]+:://; my $test_mod;
		foreach my $item (@mod_files) {
			my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
			if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { $test_mod .= &{$sub_name}; }
		}
		if ($test_mod ne "found") {
			# default action - display the modes
			$Internal_variables{nav_menu_type}  = "none";
			$MY_variables{subject} = $language_text{header_text1}; $MY_variables{store} = $language_text{header_text4};
			foreach my $key (keys %store_to_browse) {
				if (!$current_base_nodes{$store_to_browse{$key}} and !%{$store_to_browse{$key}}) { delete $store_to_browse{$key}; }
			}
			$MY_variables{products_html} = load_browse_table(\%store_to_browse, "SearchIndex=");
		}
	}
}

sub build_the_page__main {
	my $html_length;

	# Price Disclaimer
	$MY_variables{price_disclaimer} = $language_text{disclaimer_price};
	# Site Disclaimer
	$MY_variables{site_disclaimer} = $language_text{disclaimer_site};
#$debug .= qq[Price Disclaimer: $MY_variables{price_disclaimer}<br />\n];
#$debug .= qq[Site Disclaimer: $MY_variables{site_disclaimer}<br />\n];

	if ($FORM{Operation} eq "ListManiaSearch") { $MY_variables{header} = "$AWS_variables{ListName}"; }
	if (!$MY_variables{header}) { $MY_variables{header} = qq[$MY_variables{store} : $MY_variables{subject}]; }
	if ($MY_variables{error_msg} and !$Internal_variables{browse_header}) {
		$MY_variables{products_html} .= qq[<div class="apf_error">$MY_variables{error_msg}</div>];
		(my $temp_options = $Internal_variables{url_options}) =~ s/^&amp;//;
		$MY_variables{header} = qq[<a href="$MY_variables{script_name}?$temp_options">$language_text{header_text1}</a>];
	}
	build_search_box();
	$Internal_variables{html}  .= set_html("page");
	my $apf_footer = qq[<div class="apf_footer">];
	if ($MY_variables{associate_id} =~ /(freewarfrommrrat|mrratcom-21|absolutefreeb-21|mrratcom0f-22|mrratcom0d-21|mrratcom08-20)/) { $apf_footer .= qq[<br />A portion of each sale goes to benefit MrRat.com, thank you.]; }
	if ($MY_variables{associate_id} =~ /(labbswebservi-20|labbswebservi-21|lawe-21|labbswebservi-23|lawese-21|lawese-20)/) { $apf_footer .= qq[<br />A portion of each sale goes to benefit Labbs.com, thank you.]; }
	$apf_footer .= qq[</div></body>];
	$MY_variables{showhiddenscript} = qq[\n<script type="text/javascript">\nfunction showhiddenscript(linkdisplay,divname,divcontent){\ndocument.getElementById(linkdisplay).innerHTML=""\ndocument.getElementById(divname).innerHTML=divcontent\n}\n</script>\n];
	$Internal_variables{html}  =~ s/<\/head>/$MY_variables{showhiddenscript}<\/head>/i;
	$Internal_variables{html}  =~ s/<\/body>/$apf_footer/i;
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
	if ($Internal_variables{debug_state} eq "on") {
		$Internal_variables{html} = qq[---- start debug info -- Don't run the script like this in production; rename it! ----<br />\n$debug\n<br />---- end debug info ----<br /><br />\n\n] . $Internal_variables{html};
	}
	# send the page to the browser
	if ($Internal_variables{html}  =~ /DTD WML/) {
		$Internal_variables{html}  =~ s/\$(\d)/\$\$$1/g;
		$Internal_variables{html_headers} .= "Content-Type: text/vnd.wap.wml\n";
	} elsif ($Internal_variables{html}  =~ /<rss version/) {
		$Internal_variables{html_headers} .= "Content-Type: application/rss+xml\n";
	} else {
		$Internal_variables{html_headers} .= "Content-Type: text/html; charset=utf-8\n";
	}
#$Internal_variables{use_gzip} = "Yes";
#	if ($ENV{HTTP_ACCEPT_ENCODING} =~ /gzip/ and $Internal_variables{use_gzip} eq "Yes") {
#		eval 'use Compress::Zlib'; my $dbm_error .= $@;
#		if (!$dbm_error) {
#			$Internal_variables{html} = Compress::Zlib::memGzip($Internal_variables{html});
#			$Internal_variables{html_headers} .= "Content-Encoding: gzip\n";
#			my $length = length($Internal_variables{html});
#			$Internal_variables{html_headers} .= "Content-Length: $length\n"; 
#		}
#	}
	print "$Internal_variables{html_headers}\n";
	print $Internal_variables{html};
	my $this_function = "final_hook";
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
}

sub get_node_children {
	my ($parent_node,$which) = @_;
	my ($current_name, $children_result, @child_result_array,$temp_BrowseNodeId,$temp_Name);
	my $temp_url = $Internal_variables{base_url} . "&Operation=BrowseNodeLookup&BrowseNodeId=" . $parent_node;
	my $temp_result = get_url($temp_url);
	$temp_result =~ s/<Children>(.*)<\/Children>/$children_result = $1;my $x="";/es;
	my $temp_BrowseNodes = $temp_result;
	recurse_Ancestors($temp_BrowseNodes,"","browseheader");
	$MY_variables{header} = $MY_variables{browseheader};
	(my $temp_options = $Internal_variables{url_options}) =~ s/^&amp;//;
	if ($temp_options) { $temp_options = "?" . $temp_options; }
	$Internal_variables{browse_header} = qq[<a href="$MY_variables{script_name}$temp_options">$language_text{header_text4}</a> > $MY_variables{browseheader}];
#	$temp_result =~ s|.*?<BrowseNode><BrowseNodeId>([^<]+)</BrowseNodeId><Name>([^<]+)</Name>|$temp_BrowseNodeId = $1;$temp_Name = $2;my $x = "";|es;
#	$MY_variables{BrowseNodeName_display} = html_escape($temp_Name);
	push @child_result_array, ($children_result =~ /<BrowseNode>(.*?)<\/BrowseNode>/gs);
	if (!$child_result_array[1] and $which ne "nav_menu") {
		$FORM{Operation} = "ItemSearch";
		if (!$FORM{BrowseNode}) { $FORM{BrowseNode} = $parent_node; }
		delete $Internal_variables{browse_header};
		$debug .= "wait 1 second then get products<br />\n";
		sleep 1;
		goto START_PROCESSING_LABEL;	# yes i know goto is lame, bite me
	}
	foreach my $single_node (@child_result_array) {
		$single_node =~ /<BrowseNodeId>([^<]+)<\/BrowseNodeId><Name>([^<]+)<\/Name>/gs;
		my $name = $2; my $node = $1;
		if ($bad_nodes{$node}) { next; }

		# Some Amazon response variables were returning &pound; which was
		#  mangled when displayed, this simple translation fixes this problem
		$name =~ s/&pound;/£/;

		$child_nodes{html_escape($name)} = $node;
	}
	return \%child_nodes;
}

sub load_browse_table {
	my ($input1, $input2, $input3) = @_;
	my ($page_listing);
	my $i = 0;
	$MY_variables{menu_type} = $input3;
	$Internal_variables{menu_length} = keys(%{$input1});
	foreach my $key (sort keys %{$input1}) {
		if (!$current_base_nodes{$store_to_browse{$key}} and !%{$store_to_browse{$key}} and !$child_nodes{$key} and !%{$MY_variables{SearchIndex}}) { next; }
		(my $temp_key = $key) =~ s/&amp;/and/g;
		$temp_key =~ s/\s/_/g;
		$MY_variables{browse_menu_name_encoded} = url_encode($temp_key);
		$MY_variables{browse_menu_searchindex} = ${$input1}{$key};
		$MY_variables{browse_menu_url} = qq[$MY_variables{script_name}?$input2$MY_variables{browse_menu_searchindex}$Internal_variables{url_options}$Internal_variables{persistant_parameters_url_options}];
		$MY_variables{browse_menu_name} = $key;
		my $this_function = "load_browse_table_loop";
		foreach my $item (@mod_files) {
			my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
			if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
		}
		if ($input3 eq "nav_menu") {
			$page_listing .= set_html("nav_menu",$i);
		} else {
			$page_listing .= set_html("browse_menu",$i);
		}
		$i++;
	}
	undef %child_nodes;
	return $page_listing;
}

sub build_search_box {
	my ($search_subject);
	$MY_variables{search_box} = qq[<form method="get" action="$MY_variables{script_name}">];
	$MY_variables{search_box} .= $MY_variables{form_options} . $Internal_variables{persistant_parameters_form_options};
	$MY_variables{search_box} .= qq[<input type="hidden" name="Operation" value="ItemSearch" /><input type="text" name="Keywords" size="20"];
	if ($FORM{Keywords}) { ($search_subject = $FORM{Keywords}) =~ s/\+/ /g; $MY_variables{search_box} .= qq[ value="$search_subject" ]; }
	$MY_variables{search_box} .= qq[ />];
	$MY_variables{search_box} .= qq[<select name="SearchIndex">];
	if ($FORM{BrowseNode}) { $MY_variables{search_box} .= qq[<option value="node:$MY_variables{SearchIndex}:$FORM{BrowseNode}" selected="selected">$language_text{searchbox_text2}</option>]; }
#	if (!$MY_variables{SearchIndex}) {
	#	$MY_variables{search_box} .= qq[<option value="Blended"];
#		if (!$MY_variables{SearchIndex}) { $MY_variables{search_box} .= qq[ selected="selected"]; }
#		$MY_variables{search_box} .= qq[>$language_text{searchbox_text1}</option>];
#	}
	foreach my $key (sort keys %store_to_browse) {
		$MY_variables{search_box} .= qq[<option value="$store_to_browse{$key}"];
		if ($store_to_browse{$key} eq ($MY_variables{SearchIndex} or $lookup_store{$catalog_to_mode{$AWS_variables{ProductGroup}}}) and !$FORM{BrowseNode}) { $MY_variables{search_box} .= qq[ selected="selected"]; }
		$MY_variables{search_box} .= qq[>$key</option>];
	}
	#	wap
	($MY_variables{wap_search_box} = $MY_variables{search_box}) =~ s/<form[^>]+>/<p>Select Category:/;
	(my $wap_form_options = $MY_variables{form_options}) =~ s/<input type="hidden"/<postfield/g;
	$MY_variables{wap_search_box} =~ s/<input [^>]+>//g;
	$MY_variables{wap_search_box} =~ s/ selected="selected"//g;
	$MY_variables{wap_search_box} =~ s/<option value="Blended"[^<]+<\/option>//g;
	$MY_variables{wap_search_box} .= qq[Enter Keywords:<input name="Keywords" /><br /></p>\n<p><anchor>Search<go method="get" href="$MY_variables{script_name}">$wap_form_options<postfield name="Keywords" value="\$(Keywords)" /><postfield name="mode" value="\$(mode)" /></go></anchor></p>];
	#	end wap
	$MY_variables{search_box} .= qq[</select><input class="apf_submit_button_style" type="submit" value="$language_text{button_text4}" /></form>];
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
}

sub assign_variables {
	my ($whose_variables, $temp_input) = @_;
	my (@Details);
	my $i = 0;
	if (@{${$temp_input}{Item}}) {
		@Details = @{${$temp_input}{Item}};
	}
	Details_loop: foreach my $item (@Details) {
		my (%temp_hash, @descriptors, $products_html_addition);
		my @AWS_deletekeys = qw(Title CustomerReviews SimilarProducts Accessories ItemAttributes PublicationDate ReleaseDate Offers Offer OfferSummary Availability IsEligibleForSuperSaverShipping EditorialReviews Tracks ListPrice OurFormattedPrice ProductGroup Manufacturer FormattedPrice ListItemId IsAdultProduct);
		delete @AWS_variables{@AWS_deletekeys};
		my @MY_deletekeys = qw(ProductName our_price list_price discount our_value list_value my_artists my_prices ImageUrlSmall);
		delete @MY_variables{@MY_deletekeys};
		$Internal_variables{details_max}  = $#Details + 1;
		push @{$temp_hash{Details}}, $item;
		my $level_2 = process_hashes_of_arrays(\%temp_hash);
		my $level_3 = process_hashes_of_arrays($level_2);
		if ($AWS_variables{CustomerReviews}) { my_comments($level_3);	}
		if ($AWS_variables{SimilarProducts}) { get_product_links(${$level_3}{SimilarProduct}, "SimilarProduct"); }
		if ($AWS_variables{Accessories}) { get_product_links(${$level_3}{Accessory}, "Accessory"); }
		if ($AWS_variables{AlternateVersions}) { get_product_links(${$level_3}{AlternateVersion}, "AlternateVersion"); }
		if (@{${$level_3}{Format}}) { $AWS_variables{Format} = join  ", ", @{${$level_3}{Format}}; }
		if (@{${$level_3}{Platform}}) { $AWS_variables{Platform} = join  ", ", @{${$level_3}{Platform}}; }
		my $level_4 = process_hashes_of_arrays($level_3);
		$MY_variables{ProductName} = $AWS_variables{Title};
		if ($catalog_to_mode{$AWS_variables{ProductGroup}}) { $MY_variables{SearchIndex} = $catalog_to_mode{$AWS_variables{ProductGroup}}; }
		$MY_variables{my_large_image_url} = "$MY_variables{script_name}?Operation=ItemLookup&amp;ItemId=$AWS_variables{ASIN}&amp;myOperation=Image$Internal_variables{url_options}";
  	process_images($item);
		if ($AWS_variables{Offers} or $AWS_variables{OfferSummary}) {
			my_prices();
			$AWS_variables{Offer} =~ s/<Availability>([^<]+)<\/Availability>/$AWS_variables{Availability} = $1/e;
			if (!$AWS_variables{Availability}) { $AWS_variables{Availability} = "unknown"; }
			$AWS_variables{Offer} =~ s/<IsEligibleForSuperSaverShipping>([^<]+)<\/IsEligibleForSuperSaverShipping>/if ($1 eq 1) { $MY_variables{SuperSaverShipping} = "$language_text{miscellaneous8}<br \/>" }/e;
		}
		if ($AWS_variables{ItemAttributes}) {
			my_artists($level_3);
			if ($AWS_variables{Date}) { $AWS_variables{Date} =~ s/^(....)-(..)-(..)$/$months[$2-1] $3, $1/; }
			if ($AWS_variables{TheatricalReleaseDate}) { $AWS_variables{TheatricalReleaseDate} =~ s/^(....)-(..)-(..)$/$months[$2-1] $3, $1/; }
			if ($AWS_variables{PublicationDate}) { $AWS_variables{PublicationDate} =~ s/^(....)-(..)-(..)$/$months[$2-1] $3, $1/; }
			if ($AWS_variables{ReleaseDate}) { $AWS_variables{ReleaseDate} =~ s/^(....)-(..)-(..)$/$months[$2-1] $3, $1/; }
			if ($AWS_variables{PublicationDate} and !$AWS_variables{ReleaseDate}) { $MY_variables{ReleaseDate} = $AWS_variables{PublicationDate}; }
			if ($AWS_variables{SpecialFeatures}) {
				$AWS_variables{SpecialFeatures} =~ s/\^/: /g;
				$AWS_variables{SpecialFeatures} =~ s/\|/; /g;
			}
			require $Internal_variables{language_location} . "/my_descriptors.language";
			require $Internal_variables{cwd} . "/apf_descriptors_config.ini";
		}
		if ($AWS_variables{IsAdultProduct} eq "1" and $Internal_variables{display_adult} ne "Yes") { next; }
		if ($AWS_variables{EditorialReviews}) { $MY_variables{product_description} = qq[<span class="apf_heading4c">$language_text{my_product_description}</span><br /><br />] . my_editorialreviews(); }
		if ($AWS_variables{Tracks}) { my_tracks(); }
		if (@{${$level_3}{Feature}}) { my_features(${$level_3}{Feature});	}
		$MY_variables{my_availability} = qq[<span class="apf_heading4">$language_text{availability_text1}</span> $AWS_variables{Availability}\n];
		($MY_variables{old_product_url} = $AWS_variables{DetailPageURL}) =~ s|%253FSubscriptionId|/ref=nosim%253FSubscriptionId|;
		$MY_variables{wap_item_url} = "http://www.amazon.com/exec/obidos/redirect?tag=$MY_variables{associate_id}&amp;creative=$MY_variables{subscription_id}&amp;camp=2025&amp;link_code=xm2&amp;path=ct/text/vnd.wap.wml/-/tg/aa/xml/glance-xml/-/$AWS_variables{ASIN}";
		if ($Internal_variables{debug_state} ne "on") {
			$MY_variables{img_tracker} = qq[<img src="http://www.assoc-$Internal_variables{amazon_wwwsite}/e/ir?t=$MY_variables{associate_id}&l=as2&o=$Internal_variables{img_tracker_locale}&a=$AWS_variables{ASIN}" width="1" height="1" border="0" alt="" style="border:none; margin:0px;" />];
		}
		if ($FORM{Condition}) {
			$MY_variables{item_url} = "$MY_variables{script_name}?myOperation=$FORM{Condition}&amp;ItemId=$AWS_variables{ASIN}$Internal_variables{url_options}";
		} else {
			$MY_variables{item_url} = "$MY_variables{script_name}?Operation=ItemLookup&amp;ItemId=$AWS_variables{ASIN}$Internal_variables{url_options}";
			if ($FORM{Operation} eq "ListLookup") { $MY_variables{item_url} .= "&amp;ListItemId=$AWS_variables{ListItemId}"; }
		}
		$MY_variables{buy_button} = initialize_buttons("buy");
		$MY_variables{shopping_cart_button} = initialize_buttons("cart");
		$MY_variables{wishlist_button} = initialize_buttons("wishlist");
		$MY_variables{wedding_button} = initialize_buttons("wedding");
		$MY_variables{baby_button} = initialize_buttons("baby");
		if (!$AWS_variables{OfferListingId} and ($whose_variables eq "item" or $whose_variables eq "larger_image")) { $Internal_variables{merchants} = "Yes"; }
#		if ($AWS_variables{TotalNew} ne "0" and !$AWS_variables{OfferListingId} and $whose_variables eq "item") { $Internal_variables{merchants} = "Yes"; }
#		if ($AWS_variables{Availability} =~ /item is currently not available by this merchant/i and $whose_variables eq "item") { $Internal_variables{merchants} = "Yes"; }
		if ($Internal_variables{merchants}) { parse_variations(); }
		if ($FORM{myOperation} eq "CustomerReviews") {
			$Internal_variables{results_per_page} = 5;
			$AWS_variables{TotalResults} = $AWS_variables{TotalReviews};
			$Internal_variables{page_parameter} = "ReviewPage";
			$Internal_variables{current_page} = $FORM{ReviewPage};
		} elsif ($FORM{Operation} eq "ListLookup") {
			$Internal_variables{results_per_page} = 10;
			$Internal_variables{page_parameter} = "ProductPage";
			$Internal_variables{current_page} = $FORM{ProductPage};
		} else {
			$Internal_variables{results_per_page} = 10;
			$Internal_variables{page_parameter} = "ItemPage";
			$Internal_variables{current_page} = $FORM{ItemPage};
			if ($AWS_variables{TotalReviews} > 5) {
				$MY_variables{more_reviews_link} = qq[<a href="$MY_variables{script_name}?Operation=ItemLookup&amp;myOperation=CustomerReviews&amp;ItemId=$AWS_variables{ASIN}&amp;ReviewPage=2$Internal_variables{url_options}">$language_text{see_text6}</a>];
			}
		}
		if ($AWS_variables{BrowseNodes}) { parse_similar_BrowseNodes(); }
		if ($AWS_variables{TotalResults} or $AWS_variables{TotalPages}) { see_more(); }
		if ($Internal_variables{can_sort} eq "Yes" and $AWS_variables{TotalResults} > 1) { my_sort_box(); }
		my $this_function = "assign_variables_Details_loop";  my $products_html_addition;
		foreach my $item (@mod_files) {
			my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
			if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { $products_html_addition .= &{$sub_name}($level_2); }
		}
		$MY_variables{products_html} .= set_html($whose_variables,$i) . $products_html_addition;
		if ($i >= $FORM{max_results} -1) { last Details_loop; }
		$i++;
	}
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://; my @pass_value = ($whose_variables,$temp_input);
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}(\@pass_value); }
	}
}

sub see_more {
	if (!$AWS_variables{TotalPages}) {
		$AWS_variables{TotalPages} = int(($AWS_variables{TotalResults} + $Internal_variables{results_per_page} - 1)/$Internal_variables{results_per_page});
		if ($AWS_variables{TotalPages} == 0) { $AWS_variables{TotalPages} = 1; }
	}
# Increased number of pages to 400 in line with the suggestion by Tom.Paine
# <http://www.absolutefreebies.com/phpBB2/viewtopic.php?p=58813#58813>
#	if ($AWS_variables{TotalPages} > 250) { $AWS_variables{TotalPages} = 250; }
	if ($AWS_variables{TotalPages} > 400) { $AWS_variables{TotalPages} = 400; }
	$MY_variables{see_total} = qq[$language_text{see_text4} $Internal_variables{current_page} $language_text{see_text5}&nbsp; $AWS_variables{TotalPages}];
	my $see_form_options = $MY_variables{form_options} . $Internal_variables{more_form_options};
	if ($Internal_variables{current_page} < $AWS_variables{TotalPages}) {
		my $next_page = $Internal_variables{current_page} + 1;
		$see_form_options .= qq[<input type="hidden" name="$Internal_variables{page_parameter}" value="$next_page" />];
		$MY_variables{see_next} = qq[<form action="$MY_variables{script_name}" method="get">$see_form_options<input class="apf_submit_button_style" type="submit" value="$language_text{see_text1}" /></form>];
	}
	if ($Internal_variables{current_page} > 1) {
		my $prev_page = $Internal_variables{current_page} - 1;
		$see_form_options .= qq[<input type="hidden" name="$Internal_variables{page_parameter}" value="$prev_page" />];
		$MY_variables{see_prev} = qq[<form action="$MY_variables{script_name}" method="get">$see_form_options<input class="apf_submit_button_style" type="submit" value="$language_text{see_text2}" /></form>];
	}
	my ($ItemPage_low,$ItemPage_high);
	$MY_variables{see_index} = "";
	if ($AWS_variables{TotalPages} != "1") {
		if ($Internal_variables{current_page} - 5 > 0) { $ItemPage_low = $Internal_variables{current_page} - 5; } else { $ItemPage_low = "1"; }
		if ($ItemPage_low + 10 <= $AWS_variables{TotalPages}) { $ItemPage_high = $ItemPage_low + 10; } else { $ItemPage_high = $AWS_variables{TotalPages}; }
		for (my $loop_index = $ItemPage_low; $loop_index <= $ItemPage_high; $loop_index++) {
			if ($loop_index == $Internal_variables{current_page}) {
				$MY_variables{see_index} .= qq[&nbsp;$loop_index&nbsp;];
			} else {
				(my $temp_options = $Internal_variables{see_url_options}) =~ s/^&amp;//;
				$MY_variables{see_index} .= qq[&nbsp;<a href="$MY_variables{script_name}?$Internal_variables{see_url_options}$Internal_variables{url_options}&amp;$Internal_variables{page_parameter}=$loop_index">$loop_index</a>&nbsp;];
			}
		}
	}
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
}

sub get_variations {
	my $variations_page = shift;
	my ($temp_variations,$xml_result,@temp_items);
	my $this_xml_url = $Internal_variables{base_url} . "&Operation=ItemLookup&ItemId=$AWS_variables{ASIN}&ResponseGroup=Offers,Variations,Images,VariationImages&MerchantId=All&VariationPage=$variations_page";
	$debug .= "wait 1 second then get_variations<br />\n";
	sleep 1;
	my $xml_result = get_url($this_xml_url,"skip_ok");
	$xml_result =~ s/<Variations>(.*?)<\/Variations>/$temp_variations = $1;/es;
	if ($temp_variations) { push @temp_items, ($temp_variations =~ /<Item>(.*?)<\/Item>/gs); }
	return ($xml_result, \@temp_items);
}

sub parse_variations {
	my ($xml_result, $returned_items_ref, @variations_items, $loop_index, %variations_variables, %variation_prices, %ClothingSizes, @temp_size_array, @temp_ClothingSize_array, %variations_Size, $variations_prices_html, %variations_RingSize, %variations_Title, %local_imagesets_variation);
	($xml_result, $returned_items_ref) = get_variations(All);
	$xml_result =~ s/<Availability>([^<]+)<\/Availability>/$AWS_variables{Availability} = $1/e;
	delete $MY_variables{SuperSaverShipping};
	$xml_result =~ s/<IsEligibleForSuperSaverShipping>([^<]+)<\/IsEligibleForSuperSaverShipping>/if ($1 eq 1) { $MY_variables{SuperSaverShipping} = "$language_text{miscellaneous8}<br \/>" }/e;
	my ($TotalOffers, $TotalVariations);
	$xml_result =~ s/<TotalOffers>([^<]+)<\/TotalOffers>/$TotalOffers = $1/e;
	$xml_result =~ s/<TotalVariations>([^<]+)<\/TotalVariations>/$TotalVariations = $1/e;
	if (!$TotalOffers and !$TotalVariations) { return; }
	my ($temp_lowestprice_string, $temp_highestprice_string, $lowest_price, $highest_price);
	if ($xml_result =~ /LowestSalePrice/) {
		$temp_lowestprice_string = "LowestSalePrice";
		$temp_highestprice_string = "HighestSalePrice";
	} else {
		$temp_lowestprice_string = "LowestPrice";
		$temp_highestprice_string = "HighestPrice";
	}
	$xml_result =~ s/<$temp_lowestprice_string>[^F]+FormattedPrice>([^<]+)<\/FormattedPrice><\/$temp_lowestprice_string>/$lowest_price = $1/e;
	$xml_result =~ s/<$temp_highestprice_string>[^F]+FormattedPrice>([^<]+)<\/FormattedPrice><\/$temp_highestprice_string>/$highest_price = $1/e;
	if ($lowest_price) { 
		if ($lowest_price eq $highest_price) {
			$variations_prices_html = qq|<div class="apf_prices_text" id="variations_price_div">$language_text{my_prices_text6}&nbsp;<span class="apf_prices">$lowest_price</span></div>\n|;
		} else {
			$variations_prices_html = qq|<div class="apf_prices_text" id="variations_price_div">$language_text{my_prices_text6}<br />$language_text{my_prices_text7}&nbsp;<span class="apf_prices">$lowest_price</span><br />$language_text{my_prices_text8}&nbsp;<span class="apf_prices">$highest_price</span></div>\n|;
		}
		$variations_prices_html .= '<div><span class="apf_small_text">';
		# Time Stamp per Item?
		if ($Internal_variables{time_stamp_per_item} eq 'Yes') {
			$variations_prices_html .= $language_text{my_prices_text9};
		}else{
			$variations_prices_html .= $language_text{my_prices_text4};
		}
		$variations_prices_html .= qq[</span></div>\n];
	}
	push(@variations_items,@{$returned_items_ref});
	my %uniq_colors;
	foreach my $item (@variations_items) {
		my ($temp_OfferListingId,$temp_FormattedPrice,$temp_ClothingSize,$temp_Color,$temp_price_string,$temp_price_xml);
		$item =~ m/<Offer>(.*?)<\/Offer>/s;
		my $temp_offer = $1;
		$temp_offer =~ s/<OfferListingId>([^<]+)<\/OfferListingId>/$temp_OfferListingId = $1/e;
		if (!$temp_OfferListingId) { next; }
		if ($temp_offer =~ /SalePrice/) { $temp_price_string = "SalePrice"; } else { $temp_price_string = "Price"; }
		$temp_offer =~ s/<$temp_price_string>(.*?)<\/$temp_price_string>/$temp_price_xml = $1/es;
		$temp_price_xml =~ s/<FormattedPrice>([^<]+)<\/FormattedPrice>/$temp_FormattedPrice = $1/e;
		$item =~ s/<ClothingSize>([^<]+)<\/ClothingSize>/$temp_ClothingSize = $1/e;
		$item =~ s/<Size>([^<]+)<\/Size>/$variations_Size{$1} = $temp_OfferListingId/e;
		$item =~ s/<RingSize>([^<]+)<\/RingSize>/$variations_RingSize{$1} = $temp_OfferListingId/e;
		$item =~ s/<Title>([^<]+)<\/Title>/$variations_Title{$1} = $temp_OfferListingId/e;
		$item =~ s/<Color>([^<]+)<\/Color>/$temp_Color = $1/e;
		if (!$temp_ClothingSize or !$temp_Color) {
			if ($temp_Color) {
				$variations_Size{$temp_Color} = $temp_OfferListingId;
			} elsif ($temp_ClothingSize) {
				$variations_Size{$temp_ClothingSize} = $temp_OfferListingId;
			}
		} else {
			push @{$variations_variables{$temp_OfferListingId}}, $temp_ClothingSize;
			push @{$variations_variables{$temp_OfferListingId}}, $temp_Color;
			push @temp_ClothingSize_array, $temp_ClothingSize;
		}
		push @{$variations_variables{$temp_OfferListingId}}, $temp_FormattedPrice;
		if ($temp_Color and !$uniq_colors{$temp_Color}) {
			$uniq_colors{$temp_Color} = 1;
			$item =~ s/<ImageSet Category="swatch">(.*?)<\/ImageSet>/$local_imagesets_variation{$temp_Color} = $1/es;
		}
	}
	my %seen;
	my @uniq_temp_ClothingSize_array = grep {! $seen{$_} ++} @temp_ClothingSize_array;
	if (@uniq_temp_ClothingSize_array and $#variations_items > 0) {
		# it's all magic from here
		my $count = 0;
		$MY_variables{variations_html} = $variations_prices_html . qq|<form name="variations">\n<select name="ClothingSize" onChange="changeColor(this.form)">\n<option value="0">$language_text{miscellaneous3}</option>\n|;
		foreach my $item (sort @uniq_temp_ClothingSize_array) {
			$count++;
			$MY_variables{variations_html} .= qq|<option value="$count">$item</option>\n|;
			$ClothingSizes{$item} = $count;
		}
		$MY_variables{variations_html} .= qq|</select><br />\n<select disabled="true" name="variation_ASIN" onChange="changeASIN(this.form)"><option value="0">$language_text{miscellaneous4}</option></select><br />\n</form>\n|;
		$MY_variables{variations_html} .= qq|<script language="JavaScript" type="text/JavaScript">\nvar myColors = new Array();\nmyColors[0] = new Array("","Then Select Color","");\n|;
		$count = 0;
		foreach my $key (keys %variations_variables) {
			$count++;
			my ($Size,$Color,$Price) = @{$variations_variables{$key}};
			$MY_variables{variations_html} .= qq|myColors[$count] = new Array("$key","$Color","$ClothingSizes{$Size}","$Price")\n|;
		}
		$MY_variables{variations_html} .= qq|function changeColor(frmName)\n{\nfrmName.variation_ASIN.options.length = 0;\nfrmName.variation_ASIN.disabled=false;\nif (frmName.ClothingSize.value >= 0){\nfrmName.variation_ASIN.options[0] = new Option("Then Select Color",0);\nColorCount = 1;\nfor (i=0; i < myColors.length; i++) {\nif (frmName.ClothingSize.value == myColors[i][2]) {\nfrmName.variation_ASIN.options[ColorCount] = new Option(myColors[i][1],myColors[i][0]);\nColorCount++;\n}\n}\n}\n}\n|;
		$MY_variables{variations_html} .= qq|function changeASIN(frmName)\n{\ndocument.addtocart.dynamicASIN.name = "OfferListingId_" + frmName.variation_ASIN.options[frmName.variation_ASIN.selectedIndex].value;\ndocument.addtocart.submit_cart_button.disabled=false;\ndocument.addtocart.submit_cart_button.value="$language_text{button_text10}";\nchangeVariationsPriceDiv(frmName);\n}\n|;
		$MY_variables{variations_html} .= qq|function changeVariationsPriceDiv(frmName)\n{\nfor (i=0; i < myColors.length; i++) {\nif (frmName.variation_ASIN.options[frmName.variation_ASIN.selectedIndex].value == myColors[i][0]) {\ndocument.getElementById("variations_price_div").innerHTML=myColors[i][3];\n}\n}\n}|;
		$MY_variables{variations_html} .= qq|</script>|;
		$MY_variables{shopping_cart_button} = qq[<form name="addtocart" action="$MY_variables{script_name}" method="get">$MY_variables{form_options}<input type="hidden" name="cart_action" value="add" /><input type="hidden" id="dynamicASIN" value="1"/><input class="apf_submit_button_style" disabled="true" name="submit_cart_button" type="submit" value="$language_text{button_text12}" />$MY_variables{form_options}</form>];
	} elsif (keys(%variations_Size) > 1) {
		$MY_variables{variations_html} = $variations_prices_html . qq|<form name="variation">\n<select name="Size" onChange="changeASIN(this.form)">\n<option value="0">$language_text{miscellaneous5}</option>\n|;
		foreach my $key (sort keys %variations_Size) {
			$MY_variables{variations_html} .= qq|<option value="$variations_Size{$key}">$key</option>\n|;
		}
		$MY_variables{variations_html} .= qq|</select><br />\n</form>\n|;
		$MY_variables{variations_html} .= qq|<script language="JavaScript" type="text/JavaScript">\n|;
		$MY_variables{variations_html} .= qq|function changeASIN(frmName)\n{\ndocument.addtocart.dynamicASIN.name = "OfferListingId_" + frmName.Size.options[frmName.Size.selectedIndex].value;\ndocument.addtocart.submit_cart_button.disabled=false;\ndocument.addtocart.submit_cart_button.value="$language_text{button_text10}";\n}\n|;
		$MY_variables{variations_html} .= qq|</script>|;
		$MY_variables{shopping_cart_button} = qq[<form name="addtocart" action="$MY_variables{script_name}" method="get">$MY_variables{form_options}<input type="hidden" name="cart_action" value="add" /><input type="hidden" id="dynamicASIN" value="1"/><input class="apf_submit_button_style" disabled="true" name="submit_cart_button" type="submit" value="$language_text{button_text12}" /></form>];
	} elsif (keys(%variations_RingSize) > 1) {
		$MY_variables{variations_html} = $variations_prices_html . qq|<form name="variation">\n<select name="Size" onChange="changeASIN(this.form)">\n<option value="0">$language_text{miscellaneous6}</option>\n|;
		foreach my $key (sort keys %variations_RingSize) {
			$MY_variables{variations_html} .= qq|<option value="$variations_RingSize{$key}">$key</option>\n|;
		}
		$MY_variables{variations_html} .= qq|</select><br />\n</form>\n|;
		$MY_variables{variations_html} .= qq|<script language="JavaScript" type="text/JavaScript">\n|;
		$MY_variables{variations_html} .= qq|function changeASIN(frmName)\n{\ndocument.addtocart.dynamicASIN.name = "OfferListingId_" + frmName.Size.options[frmName.Size.selectedIndex].value;\ndocument.addtocart.submit_cart_button.disabled=false;\ndocument.addtocart.submit_cart_button.value="$language_text{button_text10}";\n}\n|;
		$MY_variables{variations_html} .= qq|</script>|;
		$MY_variables{shopping_cart_button} = qq[<form name="addtocart" action="$MY_variables{script_name}" method="get">$MY_variables{form_options}<input type="hidden" name="cart_action" value="add" /><input type="hidden" id="dynamicASIN" value="1"/><input class="apf_submit_button_style" disabled="true" name="submit_cart_button" type="submit" value="$language_text{button_text12}" /></form>];
	} elsif (keys(%variations_Title) > 1) {
		$MY_variables{variations_html} = $variations_prices_html . qq|<form name="variation">\n<select name="Size" onChange="changeASIN(this.form)">\n<option value="0">$language_text{miscellaneous9}</option>\n|;
		foreach my $key (sort keys %variations_Title) {
			$MY_variables{variations_html} .= qq|<option value="$variations_Title{$key}">$key</option>\n|;
		}
		$MY_variables{variations_html} .= qq|</select><br />\n</form>\n|;
		$MY_variables{variations_html} .= qq|<script language="JavaScript" type="text/JavaScript">\n|;
		$MY_variables{variations_html} .= qq|function changeASIN(frmName)\n{\ndocument.addtocart.dynamicASIN.name = "OfferListingId_" + frmName.Size.options[frmName.Size.selectedIndex].value;\ndocument.addtocart.submit_cart_button.disabled=false;\ndocument.addtocart.submit_cart_button.value="$language_text{button_text10}";\n}\n|;
		$MY_variables{variations_html} .= qq|</script>|;
		$MY_variables{shopping_cart_button} = qq[<form name="addtocart" action="$MY_variables{script_name}" method="get">$MY_variables{form_options}<input type="hidden" name="cart_action" value="add" /><input type="hidden" id="dynamicASIN" value="1"/><input class="apf_submit_button_style" disabled="true" name="submit_cart_button" type="submit" value="$language_text{button_text12}" /></form>];
	} else {
		my $temp_OfferListingId;
		$xml_result =~ s/<Offer>(.*?)<\/Offer>/$AWS_variables{Offer} = $1/es;
		$AWS_variables{Offer} =~ s/<Availability>([^<]+)<\/Availability>/$AWS_variables{Availability} = $1/e;
		$AWS_variables{Offer} =~ s/<OfferListingId>([^<]+)<\/OfferListingId>/$temp_OfferListingId = $1/e;
		my_prices();
		$AWS_variables{OfferListingId} = $temp_OfferListingId;
		$MY_variables{my_prices} =~ s/$language_text{my_prices_text2}/$language_text{my_prices_text6}/;
		$MY_variables{shopping_cart_button} = qq[<form name="addtocart" action="$MY_variables{script_name}" method="get">$MY_variables{form_options}<input type="hidden" name="cart_action" value="add" /><input type="hidden" name="OfferListingId_$temp_OfferListingId" value="1"/><input class="apf_submit_button_style" name="submit_cart_button" type="submit" value="$language_text{button_text10}" />$MY_variables{form_options}</form>];
	}
	$MY_variables{my_availability} = qq[<span class="apf_heading4">$language_text{availability_text1}</span> $AWS_variables{Availability}\n];
	process_variation_images(\%local_imagesets_variation);
}

sub my_artists {
	my $level_3 = shift;
	delete $MY_variables{my_artists};
# Addition for extra template variable required by peggylon
delete $MY_variables{no_format_artists};
if (${$level_3}{Author}) {
$MY_variables{my_artists} .= comma_separate_list(${$level_3}{Author},$language_text{my_artists_text1},"Author") . "<br>";
 $MY_variables{no_format_artists} = join(' ',@{${$level_3}{Author}});   
}
#	if (${$level_3}{Author}) { $MY_variables{my_artists} .= comma_separate_list(${$level_3}{Author},$language_text{my_artists_text1},"Author") . "<br />"; }
	if (${$level_3}{Artist}) { $MY_variables{my_artists} .= comma_separate_list(${$level_3}{Artist},$language_text{my_artists_text1},"Artist") . "<br />"; }
	if (${$level_3}{Actor}) { $MY_variables{my_artists} .= comma_separate_list(${$level_3}{Actor},$language_text{my_artists_text2},"Actor") . "<br />";	}
	if (${$level_3}{Director}) { $MY_variables{my_artists} .= comma_separate_list(${$level_3}{Director},$language_text{my_artists_text4},"Director") . "<br />"; }
	if (!$MY_variables{my_artists}) {
		if ($AWS_variables{Manufacturer}) {
			if ($MY_variables{SearchIndex} =~ /^(Apparel|Baby|Beauty|Electronics|HealthPersonalCare|HomeGarden|Kitchen|Merchants|MusicalInstruments|OfficeProducts|OutdoorLiving|PCHardware|Photo|Software|SoftwareVideoGames|SportingGoods|Tools|VideoGames)$/) {
				# Update to String replacement as suggested by Tom.Paine
				# <http://www.absolutefreebies.com/phpBB2/viewtopic.php?p=58815#58815>
				#(my $search_manufacturer_string = $AWS_variables{Manufacturer}) =~ s/ /+/g;
				(my $search_manufacturer_string = $AWS_variables{Manufacturer}) =~ s/\./\%2E/g;
				$MY_variables{my_artists} = qq[$language_text{my_artists_text3} <a href="$MY_variables{script_name}?SearchIndex=$MY_variables{SearchIndex}&amp;Operation=ItemSearch&amp;Manufacturer=$search_manufacturer_string$Internal_variables{url_options}">$AWS_variables{Manufacturer}</a><br />];
			} else {
				$MY_variables{my_artists} = qq[$language_text{my_artists_text3} $AWS_variables{Manufacturer}<br />];
			}
		}
	}
	return;
}

sub my_comments {
	my $level_3 = shift;
	my $temp_loop = 1;
	foreach my $item (@{${$level_3}{Review}}) {
		my (%temp_hash,$temp_hash1,$temp_rounded_rating,$temp_rating_display,$shortened_comment);
		push @{$temp_hash{CustomerReview}}, $item;
		$temp_hash1 = process_hashes_of_arrays(\%temp_hash);
		($temp_rounded_rating = ${$temp_hash1}{Rating}[0]) =~ s/(\.\d+)//;
		if ($1 >= .25 and $1 < .75) { $temp_rounded_rating .= "-5"; } elsif ($1 >= .75) { $temp_rounded_rating++; $temp_rounded_rating .= "-0"; } else { $temp_rounded_rating .= "-0"; }
		$temp_rating_display = qq[<img alt="${$temp_hash1}{Rating}[0] out of 5 stars" src="http://g-images.amazon.com/images/G/01/x-locale/common/customer-reviews/stars-$temp_rounded_rating.gif" />];
		if ($MY_variables{SearchIndex} eq "toys") { $temp_rating_display = ${$temp_hash1}{Rating}[0]};
		if (!${$temp_hash1}{Rating}[0]) { $temp_rating_display = $language_text{average_rating_text2}; }
		if ($MY_variables{my_comments}) { $MY_variables{my_comments} .= qq[<br /><hr width="75%" /><br />\n]; }
		$MY_variables{my_comments} .= qq[<a name="review_$temp_loop">$language_text{my_comments_text1}</a> $temp_rating_display - <span class="apf_comments_summary">${$temp_hash1}{Summary}[0]</span><br />\n${$temp_hash1}{Content}[0]<br />\n];
		$shortened_comment = ${$temp_hash1}{Content}[0];
		$shortened_comment =~ s/<([^\s|>]+)\s[^>]+>(.*?)<\/\1>/$2/gis;
		if ($Internal_variables{review_length}) {
			while (substr($shortened_comment,$Internal_variables{review_length},1) !~ /[\s|-]/ and $Internal_variables{review_length} < length($shortened_comment)) { $Internal_variables{review_length}++ }
			$shortened_comment = substr($shortened_comment,0,$Internal_variables{review_length});
			if ($Internal_variables{review_length} < length(${$temp_hash1}{Content}[0])) { $shortened_comment .= qq[ ... <a href="$MY_variables{script_name}?Operation=ItemLookup&amp;myOperation=CustomerReviews&amp;ItemId=$AWS_variables{ASIN}$Internal_variables{url_options}#review_$temp_loop">$language_text{my_comments_text2}</a>]; }
		}
		if ($MY_variables{my_shortened_comments}) { $MY_variables{my_shortened_comments} .= qq[<br /><hr width="75%" /><br />\n]; }
		$MY_variables{my_shortened_comments} .= qq[$language_text{my_comments_text1} $temp_rating_display - <span class="apf_comments_summary">${$temp_hash1}{Summary}[0]</span><br />\n$shortened_comment<br />\n];
		if ($temp_loop eq 1) {
			$MY_variables{first_review_rating_display} = $temp_rating_display; $MY_variables{first_review_summary} = ${$temp_hash1}{Summary}[0]; $MY_variables{first_review_comment} = ${$temp_hash1}{Content}[0]; $MY_variables{first_review_shortened_comment} = $shortened_comment;
		}
		$temp_loop++;
		if ($temp_loop > $Internal_variables{review_results_per_item_page}) { last; }
	}
	if (${$level_3}{AverageRating} and ${$level_3}{AverageRating}[0] != 0) {
		$AWS_variables{AverageRating} = sprintf "%.2f", ${$level_3}{AverageRating}[0];
		(my $temp_rounded_rating = $AWS_variables{AverageRating}) =~ s/(\.\d+)//;
		if ($1 >= .25 and $1 < .75) { $temp_rounded_rating .= "-5"; } elsif ($1 >= .75) { $temp_rounded_rating++; $temp_rounded_rating .= "-0"; } else { $temp_rounded_rating .= "-0"; }
		$MY_variables{my_avg_rating_display} = qq[<img alt="$AWS_variables{AvgCustomerRating} out of 5 stars" src="http://g-images.amazon.com/images/G/01/x-locale/common/customer-reviews/stars-$temp_rounded_rating.gif" />];
	} else {
		$MY_variables{my_avg_rating_display} = $AWS_variables{AverageRating} = $language_text{average_rating_text2};
	}
	$MY_variables{customer_reviews_header} = qq[<span class="apf_customer_reviews_header">$language_text{customer_reviews_text1}</span>];
	$MY_variables{average_rating_header} = qq[$language_text{average_rating_text1} $MY_variables{my_avg_rating_display}];
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
	return;
}

sub my_prices {
	delete $MY_variables{list_price}; delete $MY_variables{my_prices};
	if ($AWS_variables{Offer}) {
		$AWS_variables{Offer} =~ s/<OfferListingId>([^<]+)<\/OfferListingId>/$AWS_variables{OfferListingId} = $1;/e;
		my $ourprice;
		if ($AWS_variables{Offer} =~ /<SalePrice>/) {
			$AWS_variables{Offer} =~ s/<SalePrice>(.+)<\/SalePrice>/$ourprice = $1/e;
			($AWS_variables{OurFormattedPrice}, $MY_variables{our_value}) = process_prices($ourprice);
		} else {
			$AWS_variables{Offer} =~ s/<Price>(.+)<\/Price>/$ourprice = $1/e;
			($AWS_variables{OurFormattedPrice}, $MY_variables{our_value}) = process_prices($ourprice);
		}
		$MY_variables{our_price} = qq[<div class="apf_prices_text">$language_text{my_prices_text2}&nbsp;<span class="apf_prices">$AWS_variables{OurFormattedPrice}</span></div>];
		$AWS_variables{Offer} =~ s/<Promotions>(.*?)<\/Promotions>/$AWS_variables{Promotions} = $1;/se;
		if ($AWS_variables{Promotions}) { build_promotions(); }
	}
	if ($AWS_variables{ListPrice}) {
		($AWS_variables{ListFormattedPrice}, $MY_variables{list_value}) = process_prices($AWS_variables{ListPrice});
		if ($MY_variables{list_value} > $MY_variables{our_value}) { $MY_variables{list_price} = qq[<span class="apf_prices_text">$language_text{my_prices_text1} </span><span class="apf_prices_list">$AWS_variables{ListFormattedPrice}</span><br />]; }
	}
	if ($MY_variables{our_value} and $MY_variables{list_price}) {
		my $discount_amount = $Internal_variables{money_symbol} . (sprintf "%.2f", ($MY_variables{list_value} - $MY_variables{our_value}));
		if ($MY_variables{current_locale} eq "de") { $discount_amount =~ s/\./,/g; }
		my $discount_percent = (sprintf "%2.f", (100 - ($MY_variables{our_value} / $MY_variables{list_value})*100)) . "%";
		$MY_variables{discount} = qq[<span class="apf_prices_text">$language_text{my_prices_text3}</span> <span class="apf_prices">$discount_amount ($discount_percent)</span><br />];
	}
	if ($AWS_variables{OurFormattedPrice}) {
		if ($MY_variables{our_value} > 0) {
			$MY_variables{my_prices} = qq[<div style="white-space: nowrap;">] . $MY_variables{list_price} . $MY_variables{our_price} . $MY_variables{discount};
		} else {
			$MY_variables{my_prices} = qq[<div style="white-space: nowrap;">] . $MY_variables{our_price};
		}
		$MY_variables{my_prices} .= '<span class="apf_small_text">';
		# Time Stamp per Item?
		if ($Internal_variables{time_stamp_per_item} eq 'Yes') {
			$MY_variables{my_prices} .= $language_text{my_prices_text9};
		}else{
			$MY_variables{my_prices} .= $language_text{my_prices_text4};
		}
		$MY_variables{my_prices} .= '</span></div>';
	}
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
	return;
}

sub process_prices {
	my $prices = shift;
	my ($FormattedPrice, $Amount);
	$prices =~ s/<FormattedPrice>([^<]+)<\/FormattedPrice>/$FormattedPrice = $1;/e;
	$prices =~ s/<Amount>([^<]+)<\/Amount>/$Amount = $1;/e;
	if ($MY_variables{current_locale} eq "de" and $Amount != 0) {
		$Amount =~ s/\.//g; $Amount =~ s/,/./;
	} else {
		$Amount =~ s/,//g;
	}
	if ($Amount !~ /\./) { $Amount /= 100; }
#	$Amount =~ s/^(?:(?:\$|£|EUR )(\d+(?:\.\d*)?|\.\d+))?.*$/$1/;
	return ($FormattedPrice, $Amount);
}

sub build_promotions {
	my (@promotion, $counter, $temp_html);
	$AWS_variables{Promotions} =~ s/<Summary>(.*?)<\/Summary>/push(@promotion,$1);/gse;
	foreach my $item (@promotion) {
		$item =~ s/<([^>]+?)(?:\s[^>]+)?>(.*?)<\/\1>/$AWS_variables{$1} = $2;/gse;
		if ($AWS_variables{BenefitDescription} and $AWS_variables{TermsAndConditions}) {
			$counter += 1;
			$AWS_variables{BenefitDescription} = html_escape($AWS_variables{BenefitDescription});
			my $temp_hrefname = "BenefitDescription$counter";
			my $temp_linkdisplay = "TermsAndConditions$counter";
			my $temp_divname = "PromotionHidden$counter";
			(my $temp_divcontent = $AWS_variables{TermsAndConditions}) =~ s/[\r|\n|\'|\"]//gs;
			$temp_divcontent =~ s/\&\#39\;/\\\&\#39\;/gs;
			my $temp_html = qq[<span class="apf_promotiondescription" name="$temp_hrefname">$AWS_variables{BenefitDescription}</span>];
			$temp_html .= qq[<span id="$temp_linkdisplay"> <a href="#$temp_hrefname" onclick="showhiddenscript('$temp_linkdisplay','$temp_divname','$temp_divcontent')">$language_text{my_alternateversions_text2}</a><br /></span><br />];
			$temp_html .= qq[<div class="apf_promotiondetails" id="$temp_divname"></div>];
			$MY_variables{my_promotions} .= $temp_html;
		}
	}
}

sub my_editorialreviews {
	my (@temp_array,$result);
	push @temp_array, ($AWS_variables{EditorialReviews} =~ /<EditorialReview>(.*?)<\/EditorialReview>/gs);
	foreach my $item (@temp_array) {
		my ($source,$content);
		$item =~ s/<Source>(.*?)<\/Source>/$source = $1/e;
		$item =~ s/<Content>(.*?)<\/Content>/$content = $1/e;
		$result .= qq[<span class="apf_heading4">$source:</span><br />$content<br /><br />\n];
	}
	return $result;
}

sub my_tracks {
	my %discs;
	$AWS_variables{Tracks} =~ s/<Disc Number=["']([^"']+)["']>(.*?)<\/Disc>/$discs{$1} = $2;/gse;
	foreach my $key (sort keys %discs) {
		$MY_variables{my_tracks} .= qq[<span class="apf_heading4c">$language_text{my_descriptors_text_a} $key:</span><ol>];
		$discs{$key} =~ s/<Track\s[^>]+>([^<]+)<\/Track>/my_tracks_links($1);/eg;
		$MY_variables{my_tracks} .= qq[</ol>\n];
	}
}

sub my_tracks_links {
	my $input = shift;
	my $temp_1 = url_encode($input);
	if ($lookup_store{MusicTracks}) {
		$MY_variables{my_tracks} .= qq[<li><a href="$MY_variables{script_name}?Operation=ItemSearch&amp;SearchIndex=MusicTracks&amp;Keywords=$temp_1$Internal_variables{url_options}">$input</a></li>];
	} else {
		$MY_variables{my_tracks} .= qq[<li>$input</li>];
	}
}

sub my_features {
	my $temp_feature = shift;
	$MY_variables{my_features} .= qq[<span class="apf_heading4c">$language_text{my_features_text1}</span><ul>];
	foreach my $item (@{$temp_feature}) {
		$MY_variables{my_features} .= "<li>$item<\/li>";
	}
	$MY_variables{my_features} .= qq[</ul>\n];
}

sub process_images {
	my ($imageset_primary);
	if ($no_image_image_hash{$MY_variables{SearchIndex}}) {
		$MY_variables{noimage} = $no_image_image_hash{$MY_variables{SearchIndex}};
	} else {
		$MY_variables{noimage} = $no_image_image_hash{Default};
	}
	$AWS_variables{ImageSets} =~ s/<ImageSet Category="primary">(.*?)<\/ImageSet>/$imageset_primary = $1/es;
	if ($imageset_primary) {
		parse_images($imageset_primary,"ImageUrl");
		process_variant_images();
	} else {
		my $item_xml = shift;
		parse_images($item_xml,"ImageUrl");
	}
}

sub parse_images {
	my ($image_xml,$variant_name) = @_;
	my @MY_deletekeys = ($variant_name . "SwatchHeight", $variant_name . "SwatchWidth", $variant_name . "SmallHeight", $variant_name . "SmallWidth", $variant_name . "MediumHeight", $variant_name . "MediumWidth", $variant_name . "LargeHeight", $variant_name . "LargeWidth");
	delete @MY_variables{@MY_deletekeys};
	$MY_variables{$variant_name . "Small"} = $MY_variables{noimage};
	$MY_variables{$variant_name . "Medium"} = $MY_variables{noimage};
	$MY_variables{$variant_name . "Large"} = $MY_variables{noimage};
	$image_xml =~ s/<SwatchImage><URL>([^<]+)<\/URL>(?:<Height Units="pixels">([^<]+)<\/Height><Width Units="pixels">([^<]+)<\/Width>)?/$MY_variables{$variant_name . "Swatch"} = $1;$MY_variables{$variant_name . "SwatchHeight"} = qq[height="$2"];$MY_variables{$variant_name . "SwatchWidth"} = qq[width="$3"];/es;
	$image_xml =~ s/<SmallImage><URL>([^<]+)<\/URL>(?:<Height Units="pixels">([^<]+)<\/Height><Width Units="pixels">([^<]+)<\/Width>)?/$MY_variables{$variant_name . "Small"} = $1;$MY_variables{$variant_name . "SmallHeight"} = qq[height="$2"];$MY_variables{$variant_name . "SmallWidth"} = qq[width="$3"];/es;
	$image_xml =~ s/<MediumImage><URL>([^<]+)<\/URL>(?:<Height Units="pixels">([^<]+)<\/Height><Width Units="pixels">([^<]+)<\/Width>)?/$MY_variables{$variant_name . "Medium"} = $1;$MY_variables{$variant_name . "MediumHeight"} = qq[height="$2"];$MY_variables{$variant_name . "MediumWidth"} = qq[width="$3"];/es;
	$image_xml =~ s/<LargeImage><URL>([^<]+)<\/URL>(?:<Height Units="pixels">([^<]+)<\/Height><Width Units="pixels">([^<]+)<\/Width>)?/$MY_variables{$variant_name . "Large"} = $1;$MY_variables{$variant_name . "LargeHeight"} = qq[height="$2"];$MY_variables{$variant_name . "LargeWidth"} = qq[width="$3"];/es;
	if ($MY_variables{$variant_name . "Small"} ne $MY_variables{noimage}) {
		if ($MY_variables{$variant_name . "Medium"} eq $MY_variables{noimage}) {
			$MY_variables{$variant_name . "Medium"} = $MY_variables{$variant_name . "Small"};
		}
		if ($MY_variables{$variant_name . "Large"} eq $MY_variables{noimage}) {
			$MY_variables{$variant_name . "Large"} = $MY_variables{$variant_name . "Medium"};
		}
	}
}

sub process_variant_images {
	delete $MY_variables{variant_images};
	$MY_variables{variant_image_height} = qq[height="30"];
	$MY_variables{variant_image_width} = qq[width="30"];
	push my @imagesets_variant_array, ($AWS_variables{ImageSets} =~ /<ImageSet Category="variant">(.*?)<\/ImageSet>/gs);
	my $variant_counter = 0;
	foreach my $item (@imagesets_variant_array) {
		++$variant_counter;
		parse_images($item,"VariantImage" . $variant_counter);
		$MY_variables{my_large_image_url_variant} = "$MY_variables{my_large_image_url}&amp;variant_image=$variant_counter";
		$MY_variables{variant_SmallImageUrl} = $MY_variables{"VariantImage" . $variant_counter . "Small"};
		if ($FORM{myOperation} eq "Image") {
			$MY_variables{variant_image_height} = $MY_variables{"VariantImage" . $variant_counter . "SmallHeight"};
			$MY_variables{variant_image_width} = $MY_variables{"VariantImage" . $variant_counter . "SmallWidth"};
		}
		$MY_variables{variant_images} .= set_html("variant_images");
	}
	$MY_variables{variant_images} .= qq[<br />];
	if ($FORM{variant_image}) {
		$MY_variables{ImageUrlLarge} = $MY_variables{"VariantImage" . $FORM{variant_image} . "Large"};
		$MY_variables{ImageUrlLargeHeight} = $MY_variables{"VariantImage" . $FORM{variant_image} . "LargeHeight"};
		$MY_variables{ImageUrlLargeWidth} = $MY_variables{"VariantImage" . $FORM{variant_image} . "LargeWidth"};
	}
}

sub process_variation_images {
	my $imagesets_variation = shift;
	delete $MY_variables{variation_images};
	my $variation_counter = 0;
	foreach my $key (sort keys %{$imagesets_variation}) {
		$MY_variables{variation_image_name} = $key;
		++$variation_counter;
		parse_images(${$imagesets_variation}{$key},"VariationImage" . $variation_counter);
		$MY_variables{my_large_image_url_variation} = "$MY_variables{my_large_image_url}&amp;variation_image=$variation_counter";
		my $variation_SwatchImage_name = qq[VariationImage] . $variation_counter . qq[Swatch];
		$MY_variables{variation_SwatchImageUrl} = $MY_variables{"VariationImage" . $variation_counter . "Swatch"};
		$MY_variables{variation_images} .= set_html("variation_images");
	}
	$MY_variables{variation_images} .= qq[<br />];
	if ($FORM{variation_image}) {
		$MY_variables{ImageUrlLarge} = $MY_variables{"VariationImage" . $FORM{variation_image} . "Large"};
#		$MY_variables{ImageUrlLargeHeight} = $MY_variables{"VariationImage" . $FORM{variation_image} . "LargeHeight"};
#		$MY_variables{ImageUrlLargeWidth} = $MY_variables{"VariationImage" . $FORM{variation_image} . "LargeWidth"};
		$MY_variables{ImageUrlLarge} =~ s/\.SWCH\./\./;
		delete $MY_variables{ImageUrlLargeHeight};
		delete $MY_variables{ImageUrlLargeWidth};
	}
}


sub parse_similar_BrowseNodes {
	my ($index_length,$loop_index);
	my $temp_BrowseNodes = $AWS_variables{BrowseNodes};
	$temp_BrowseNodes =~ s/<BrowseNodes>/<\/BrowseNode>/;
	$temp_BrowseNodes =~ s/<\/BrowseNodes>/<BrowseNode>/;
	push my @temp_items, ($temp_BrowseNodes =~ /<BrowseNode>.*?(?:<Ancestors>.*?<\/Ancestors>)+<\/BrowseNode>/g);
	if ($#temp_items > 9) {
		$index_length = 9;
	} else {
		$index_length = $#temp_items;
	}
	for ($loop_index = 0; $loop_index <= $index_length; $loop_index++) {
  	recurse_Ancestors($temp_items[$loop_index],"","temp_similar_browsenodes");
  	$MY_variables{similar_browsenodes} .= "<li>" . $MY_variables{temp_similar_browsenodes} . "</li>";
	}
	$MY_variables{similar_browsenodes} = qq[<ul>$MY_variables{similar_browsenodes}</ul>\n];
	my $temp_hrefname = "similar_browsenodes_header";
	my $temp_linkdisplay = "similar_browsenodes_link";
	my $temp_divname = "similar_browsenodes_div";
	(my $temp_divcontent = $MY_variables{similar_browsenodes}) =~ s/[\r|\n|\'|\"]//gs;
	$temp_divcontent =~ s/\&\#39\;/\\\&\#39\;/gs;
	my $temp_html = qq[<span class="apf_heading4c" name="$temp_hrefname">$language_text{miscellaneous7}</span>];
	$temp_html .= qq[<span id="$temp_linkdisplay"> <a href="#$temp_hrefname" onclick="showhiddenscript('$temp_linkdisplay','$temp_divname','$temp_divcontent')">$language_text{my_alternateversions_text2}</a><br /></span><br />];
	$temp_html .= qq[<div id="$temp_divname"></div>];
	$MY_variables{similar_browsenodes} = $temp_html;
}


sub recurse_Ancestors {
	my ($temp_BrowseNodes,$temp_html,$variable_name) = @_;
	my ($temp_BrowseNodeId,$temp_Name,$islast,$change_searchindex);
	$temp_BrowseNodes =~ s|.*?<BrowseNode><BrowseNodeId>([^<]+)</BrowseNodeId><Name>([^<]+)</Name>|$temp_BrowseNodeId = $1;$temp_Name = $2;my $x = "";|es;
	$temp_Name = html_escape($temp_Name);
	if ($temp_html) {	$temp_html = " > " . $temp_html; }
	my $ancestors_path = "";
#	my $ancestors_SearchIndex = $MY_variables{SearchIndex};
	$temp_Name =~ s/^(de-|ca-|fr-|jp-)//;
#	if ($temp_Name eq "ce" and ($MY_variables{SearchIndex} eq "Photo" or $MY_variables{SearchIndex} eq "PCHardware")) {
#		$ancestors_SearchIndex = "Electronics";
#	} elsif (($temp_Name eq "music" or $temp_Name eq "music") and $MY_variables{SearchIndex} eq "Classical") {
#		$ancestors_SearchIndex = "Music";
#	}
#	if ($catalog_to_mode{$temp_Name} eq $ancestors_SearchIndex) {
#		$temp_Name = $lookup_store{$catalog_to_mode{$temp_Name}};
#	} elsif ($temp_Name eq $ancestors_SearchIndex) {
#		$temp_Name = $lookup_store{$temp_Name};
#	} else {
#		$ancestors_path = "&amp;BrowseNode=$temp_BrowseNodeId";
#	}
	if ($temp_BrowseNodes !~ /<Ancestors>/) { $islast = "yes"; }
	if ($islast eq "yes" and $catalog_to_mode{$temp_Name}) {
		$change_searchindex = $catalog_to_mode{$temp_Name};
		$temp_Name = $lookup_store{$change_searchindex};
	} elsif ($islast eq "yes" and $lookup_store{$temp_Name}) {
		$change_searchindex = $temp_Name;
		$temp_Name = $lookup_store{$change_searchindex};
	} else {
		$ancestors_path = "&amp;BrowseNode=$temp_BrowseNodeId";
	}
	$temp_html = qq[<a href="$MY_variables{script_name}?SearchIndex=$MY_variables{SearchIndex}$ancestors_path$Internal_variables{url_options}">$temp_Name</a>] . $temp_html;
	if ($islast eq "yes") {
		if ($change_searchindex) { $temp_html =~ s/SearchIndex=$MY_variables{SearchIndex}/SearchIndex=$change_searchindex/g; }
		$MY_variables{$variable_name} = $temp_html
	} else {
		$temp_BrowseNodes =~ s/<Ancestors>//;
		recurse_Ancestors($temp_BrowseNodes,$temp_html,$variable_name);
	}
}


sub get_product_links {
	my ($temp_input, $response_group) = @_;
	my $temp_loop = 1;
	my ($temp_products_hidden,$temp_products,$temp_products_images,$temp_variable_name1,$temp_variable_name2,$temp_language_name,%temp_unique_hash);
	foreach my $item (@{$temp_input}) {
		my ($temp_asin, $temp_product_name, $temp_binding);
		$item =~ s/<ASIN>([^<]+)<\/ASIN>/$temp_asin = $1/e;
		$item =~ s/<Title>([^<]+)<\/Title>/$temp_product_name = $1/e;
		$item =~ s/<Binding>([^<]+)<\/Binding>/$temp_binding = $1/e;
		$temp_product_name = html_escape($temp_product_name);
		$temp_binding = html_escape($temp_binding);
		if ($temp_asin and $temp_product_name and !$temp_unique_hash{$temp_asin}) {
			$temp_unique_hash{$temp_asin} = 1;
			$temp_products .= qq[<li><a href="$MY_variables{script_name}?Operation=ItemLookup&amp;ItemId=$temp_asin$Internal_variables{url_options}">$temp_product_name</a>];
			if ($temp_binding) { $temp_products .= qq[ ($temp_binding)]; }
			$temp_products .= qq[</li>];
			$temp_products_images .= qq[<a href="$MY_variables{script_name}?Operation=ItemLookup&amp;ItemId=$temp_asin$Internal_variables{url_options}"><img border="0" src="http://images.amazon.com/images/P/$temp_asin.01.THUMBZZZ.jpg" /></a>&nbsp;];
		}
		if ($temp_binding) { $temp_products_hidden = $temp_products; }
	}
	if ($response_group eq "CartSimilarProducts") { $temp_variable_name1 = "shopping_cart_similar_products"; $temp_variable_name2 = "shopping_cart_similar_products_images"; $temp_language_name = "my_similar_products_text1"; }
	if ($response_group eq "SimilarProduct") { $temp_variable_name1 = "my_similar_products"; $temp_variable_name2 = "my_similar_products_images"; $temp_language_name = "my_similar_products_text1"; }
	if ($response_group eq "Accessory") { $temp_variable_name1 = "my_accessories"; $temp_variable_name2 = "my_accessories_images"; $temp_language_name = "my_accessories_text1"; }
	if ($temp_products) {
		$MY_variables{$temp_variable_name1} = qq[<span class="apf_heading4c">$language_text{$temp_language_name}</span>$temp_products_hidden<ul>$temp_products];
		if ($response_group eq "SimilarProduct") { $MY_variables{$temp_variable_name1} .= qq[<li><a href="$MY_variables{script_name}?Operation=SimilarityLookup&amp;ItemId=$AWS_variables{ASIN}$Internal_variables{url_options}">$language_text{see_text6}</a></li>]; }
		$MY_variables{$temp_variable_name1} .= qq[</ul>];
		$MY_variables{$temp_variable_name2} = qq[<span class="apf_heading4c">$language_text{$temp_language_name}</span><br />$temp_products_images<a href="$MY_variables{script_name}?Operation=SimilarityLookup&amp;ItemId=$AWS_variables{ASIN}$Internal_variables{url_options}">$language_text{see_text6}</a><br />];
	}
	if ($temp_products_hidden) {
		my $temp_hrefname = "alternateversionsheader";
		my $temp_linkdisplay = "alternateversionslink";
		my $temp_divname = "alternateversionshidden";
		(my $temp_divcontent = $temp_products) =~ s/[\r|\n|\'|\"]//gs;
		$temp_divcontent =~ s/\&\#39\;/\\\&\#39\;/gs;
		$temp_divcontent = qq[<ul>$temp_divcontent</ul>];
		my $temp_html = qq[<span class="apf_heading4c" name="$temp_hrefname">$language_text{my_alternateversions_text1}</span>];
		$temp_html .= qq[<span id="$temp_linkdisplay"> <a href="#$temp_hrefname" onclick="showhiddenscript('$temp_linkdisplay','$temp_divname','$temp_divcontent')">$language_text{my_alternateversions_text2}</a><br /></span><br />];
		$temp_html .= qq[<div id="$temp_divname"></div>];
		$MY_variables{my_alternateversions} .= $temp_html;
	}
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
}


sub my_sort_box {
	my (@temp_sort_array,$sort_box_options,$sortIndex);
	if ($FORM{SearchIndex}) {
		$sortIndex = $FORM{SearchIndex};
	} else {
		$sortIndex = $MY_variables{SearchIndex};
	} 
	@temp_sort_array = @{$sort_hash_by_mode{$sortIndex}};
	foreach my $key1 (sort {$sort_hash{$a} cmp $sort_hash{$b}} keys %sort_hash) {
		if (grep { $_ eq $key1 } @temp_sort_array) {
			$sort_box_options .= qq[<option value="$key1"];
			if ($key1 eq $FORM{Sort}) {
				$sort_box_options .= qq[ selected="selected"];
			} elsif ($key1 eq "salesrank" and !$FORM{Sort}) {
				$sort_box_options .= qq[ selected="selected"];
			}
			$sort_box_options .= qq[>$sort_hash{$key1}</option>];
		}
	}
	my $sort_form_options = $MY_variables{form_options};
	($sort_form_options .= $Internal_variables{more_form_options} ) =~ s|<input type="hidden" name="Sort" value="[^"]+" />||;
	$MY_variables{sort_box} = qq[<form method="get" action="$MY_variables{script_name}">$sort_form_options<select name="Sort">$sort_box_options</select><input class="apf_submit_button_style" type="submit" value=" $language_text{button_text6} " /></form>];
}

sub shopping_cart {
	my ($this_xml_url, $xml_result);
	(my $temp_options = $Internal_variables{see_url_options}) =~ s/^&amp;//;
	if (!$MY_variables{associate_id}) { $Internal_variables{html}  = "<h1>No associate_id found!</h1>"; }
	$Internal_variables{use_cache} = "no";
	$MY_variables{store} = "Shopping"; $MY_variables{subject} = "Cart"; $MY_variables{header} = $language_text{cart_text1};
	if ($FORM{cart_action} eq "get") {
		if (!$Internal_variables{session}) {
			$MY_variables{products_html} = $language_text{cart_text2};
			erase_cookies();
			$MY_variables{header} = qq[<a href="$MY_variables{script_name}?$temp_options">$language_text{header_text1}</a>];
			return;
		}
		$this_xml_url = $Internal_variables{base_url} . "&Operation=CartGet$Internal_variables{session}&ResponseGroup=Cart,CartSimilarities";
	} elsif ($FORM{cart_action} eq "add") {
		my ( $temp_cart_action, %item_hash, $items_quantities, %ListItemId_hash );
		if ($Internal_variables{session}) {
			$temp_cart_action = "&Operation=CartAdd$Internal_variables{session}";
		} else {
			$temp_cart_action = "&Operation=CartCreate";
		}
		if ($ENV{QUERY_STRING} =~ /cart_item_/) {
			$ENV{QUERY_STRING} =~ s/cart_item_([^=]+)=([^&]+)/if ($2 > 0) { $item_hash{$1} += $2; }/ge;
			my $item_counter = 0;
			foreach my $item_key (keys %item_hash) {
				$item_counter++;
				$items_quantities .= "&Item.$item_counter.ASIN=$item_key&Item.$item_counter.Quantity=$item_hash{$item_key}";
			}
		}
		if ($ENV{QUERY_STRING} =~ /OfferListingId_/) {
			$ENV{QUERY_STRING} =~ s/OfferListingId_([^=]+)=([^&]+)(?:&ListItemId=([^&]+))?/if ($2 > 0) { $item_hash{$1} += $2; $ListItemId_hash{$1} = $3; }/ge;
			my $item_counter = 0;
			foreach my $item_key (keys %item_hash) {
				$item_counter++;
				if ($ListItemId_hash{$item_key}) {
					my ($temp_listitemid,$temp_asin);
					$ListItemId_hash{$item_key} =~ s/([^_]+)_(.*)/$temp_listitemid = $1; $temp_asin = $2;/e;
					$items_quantities .= "&Item.$item_counter.ASIN=$temp_asin&Item.$item_counter.Quantity=$item_hash{$item_key}&Item.$item_counter.ListItemId=$temp_listitemid";
				} else {
					$items_quantities .= "&Item.$item_counter.OfferListingId=$item_key&Item.$item_counter.Quantity=$item_hash{$item_key}";
				}
			}
		}
		$this_xml_url = $Internal_variables{base_url} . "$temp_cart_action$items_quantities&ResponseGroup=Cart,CartSimilarities";
	} elsif ($FORM{cart_action} eq "clear") {
		if (!$Internal_variables{session}) {
			$MY_variables{products_html} = $language_text{cart_text2};
			erase_cookies();
			$MY_variables{header} = qq[<a href="$MY_variables{script_name}?$temp_options">$language_text{header_text1}</a>];
			return;
		}
		erase_cookies();
		my $temp_url = $Internal_variables{base_url} . "&Operation=CartClear$Internal_variables{session}&ResponseGroup=Cart";
		my $temp_result = get_url($temp_url);
		$Internal_variables{session} = "";
		$MY_variables{products_html} = $language_text{cart_text2};
		erase_cookies();
		$MY_variables{header} = qq[<a href="$MY_variables{script_name}?$temp_options">$language_text{header_text1}</a>];
		(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
		foreach my $item (@mod_files) {
			my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
			if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
		}
		return;
	} elsif ($FORM{cart_action} eq "modify") {
		if (!$Internal_variables{session}) {
			$MY_variables{products_html} = $language_text{cart_text2};
			erase_cookies();
			$MY_variables{header} = qq[<a href="$MY_variables{script_name}?$temp_options">$language_text{header_text1}</a>];
			return;
		}
		my (%item_hash,$items_quantities,$i);
		$ENV{QUERY_STRING} =~ s/cart_item_([^=]+)=([^&]+)/$item_hash{$1} = $2;/ge;
		foreach my $item_key (keys %item_hash) {
			$i++;
			$items_quantities .= "&Item.$i.CartItemId=$item_key&Item.$i.Quantity=$item_hash{$item_key}";
		}
		$this_xml_url = $Internal_variables{base_url} . "&Operation=CartModify$Internal_variables{session}$items_quantities&ResponseGroup=Cart,CartSimilarities";
		if (!$items_quantities) { delete $MY_variables{error_msg}; $FORM{cart_action} = "clear"; shopping_cart(); return; }
	}
	my $level_2;
	if ($this_xml_url) {
		$MY_variables{error_msg} = "";
		$xml_result = get_url($this_xml_url);
		my $level_1 = parse_xml_into_hashes_of_arrays($xml_result);
		$level_2 = process_hashes_of_arrays($level_1);
	}
	my $i = 0;
	$MY_variables{total_cart_items} = $#{${$level_2}{CartItem}} + 1;
	if (!$Internal_variables{session} and $FORM{cart_action} eq "add") { $Internal_variables{html_headers} .= "Set-Cookie: apfcart_$MY_variables{current_locale}=$AWS_variables{CartId},$AWS_variables{URLEncodedHMAC};\n"; }
	my $whose_variables = "shopping_cart";
	$MY_variables{continue_shopping} = qq[<a href="javascript:history.go(-1)"  onmouseout="self.status='';return true" onmouseover="self.status=document.referrer;return true"><button name="buy" class="apf_submit_button_style" style="font-size:12;font-weight:bold;text-decoration:none;">&lt; %%see_text3%%</button></a>];
	if (!$AWS_variables{PurchaseURL}) { $AWS_variables{PurchaseURL} = "http://www.$Internal_variables{amazon_wwwsite}/gp/cart/aws-merge.html?$Internal_variables{session}&associate-id=$MY_variables{associate_id}&SubscriptionId=$MY_variables{subscription_id}"; }
	$MY_variables{checkout} = qq[<a href="$AWS_variables{PurchaseURL}"><img alt="Buy from Amazon.com" border="0" src="http://g-images.amazon.com/images/G/01/associates/add-to-cart.gif" /></a>];
#	push my @cart_asin_array, ($AWS_variables{CartItems} =~ /<ASIN>(.*?)<\/ASIN>/gsi);
	my @CartSimilarProducts_array;
	push @CartSimilarProducts_array, ($AWS_variables{SimilarProducts} =~ /<SimilarProduct>(.*?)<\/SimilarProduct>/gsi);
	push @CartSimilarProducts_array, ($AWS_variables{OtherCategoriesSimilarProducts} =~ /<OtherCategoriesSimilarProduct>(.*?)<\/OtherCategoriesSimilarProduct>/gsi);
	if (@CartSimilarProducts_array) { get_product_links(\@CartSimilarProducts_array, "CartSimilarProducts"); }
	$AWS_variables{SubTotal} =~ s/<FormattedPrice>([^<]+)<\/FormattedPrice>/$MY_variables{cart_price_total} = $1/e;
	foreach my $single_item (@{${$level_2}{CartItem}}) {
		my (%temp_hash);
		delete $AWS_variables{Title};
		push @{$temp_hash{Item}}, $single_item;
		my $temp_hash1 = process_hashes_of_arrays(\%temp_hash);
		my $temp_hash2 = process_hashes_of_arrays($temp_hash1);
		my $temp_hash3 = process_hashes_of_arrays($temp_hash2);
#		push @cart_asin_array, $AWS_variables{ASIN};
		if ($AWS_variables{Amount} !~ /\./) { $AWS_variables{Amount} /= 100; }
		$MY_variables{my_cartid} = $AWS_variables{CartItemId};
		$AWS_variables{ItemTotal} =~ s/<FormattedPrice>([^<]+)<\/FormattedPrice>/$MY_variables{my_cart_item_price} = $1/e;
		$AWS_variables{Price} =~ s/<FormattedPrice>([^<]+)<\/FormattedPrice>/$MY_variables{my_cart_item_single_price} = $1/e;
		$MY_variables{cart_qty_total} += $AWS_variables{Quantity};
		if (!$AWS_variables{Title}) { $AWS_variables{Title} = $AWS_variables{ASIN}; }
		$MY_variables{products_html} .= set_html($whose_variables,$i);
		$i++;
		(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
		foreach my $item (@mod_files) {
			my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
			if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
		}
	}
	$Internal_variables{html_headers} .= "Set-Cookie: apfcartcontents_$MY_variables{current_locale}=$MY_variables{cart_qty_total},$MY_variables{cart_price_total};\n";
	if (!$MY_variables{cart_qty_total} and !$MY_variables{error_msg} and !$AWS_variables{ErrorMsg}) {
		$MY_variables{products_html} = $language_text{cart_text2};
		erase_cookies();
		$MY_variables{header} = qq[<a href="$MY_variables{script_name}?$temp_options">$language_text{header_text1}</a>];
	}
}

sub erase_cookies {
	$Internal_variables{html_headers} .= "Set-Cookie: apfcart_$MY_variables{current_locale}=empty; expires=Sun 01-Jan-01 01:01:01 GMT;\n";
	$Internal_variables{html_headers} .= "Set-Cookie: apfcartcontents_$MY_variables{current_locale}=empty; expires=Sun 01-Jan-01 01:01:01 GMT;\n";
}

sub get_extra_product_links {
	my $value = shift;
	my (@temp_xml_feed,$my_temp,$temp_cart,$cart_counter);
	my $temp_asins = join(",", @{$value});
	my $temp_url = $Internal_variables{base_url} . "&Operation=SimilarityLookup&ItemId=$temp_asins&ResponseGroup=$Internal_variables{ResponseGroup_Products}";
	$debug .= "wait 1 second then get_extra_product_links<br />\n";
	sleep 1;
	my $temp_xml_result = get_url($temp_url,"skip_ok");
	push @temp_xml_feed, ($temp_xml_result =~ /<Item>(.*?)<\/Item>/gsi);
	for my $ii (0 .. $#temp_xml_feed) {
		my ($temp_asin,$temp_product_name,$temp_our_price,$temp_availability,$temp_OfferListingId,$row_color);
		$temp_xml_feed[$ii] =~ s/<ASIN>([^<]+)<\/ASIN>/$temp_asin = $1/sie;
		$temp_xml_feed[$ii] =~ s/<Title>([^<]+)<\/Title>/$temp_product_name = $1/sie;
		$temp_xml_feed[$ii] =~ s/<OfferListing>.*?<FormattedPrice>([^<]+)<\/FormattedPrice>/$temp_our_price = $1/sie;
		$temp_xml_feed[$ii] =~ s/<Availability>([^<]+)<\/Availability>/$temp_availability = $1/sie;
		$temp_xml_feed[$ii] =~ s/<OfferListingId>([^<]+)<\/OfferListingId>/$temp_OfferListingId = $1/e;
		$my_temp .= qq[<li><a href="$MY_variables{script_name}?Operation=ItemLookup&amp;ItemId=$temp_asin$Internal_variables{url_options}">$temp_product_name</a></li>\n];
		if ($AWS_variables{OfferListingId}) {
			if ($ii/2 == int($ii/2)) { $row_color = "apf_even_row"; } else { $row_color = "apf_odd_row"; }
			$temp_cart .= qq[<div class="apf_checkbox"><span class="apf_prices">$temp_our_price </span><input type="checkbox" name="cart_item_$temp_asin" value="1" ];
			if (!$temp_OfferListingId) { $temp_cart .= qq[style="visibility:hidden;" ]; }
			$temp_cart .= qq[/></div><div class="$row_color"><a href="$MY_variables{script_name}?Operation=ItemLookup&amp;ItemId=$temp_asin$Internal_variables{url_options}">$temp_product_name</a></div>];
		}
	}
	(my $this_function = (caller(0))[3]) =~ s/[^:]+:://;
	foreach my $item (@mod_files) {
		my $returned_value;
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { $returned_value = &{$sub_name}($my_temp); }
		if ($returned_value) { $my_temp = $returned_value; }
	}
	return $my_temp, $temp_cart;
}

sub comma_separate_list {
	my($temp_array_ref,$temp_list_start,$temp_Operation,$temp_list,$temp_search_string,$item) = @_;
	foreach $item (@{$temp_array_ref}) {
		if ($temp_list) { $temp_list .= ", "; } else { $temp_list = "$temp_list_start "; }
#		($temp_search_string = $item) =~ s/ /+/g;
		$temp_search_string = url_encode("'".$item."'");
		$temp_list .= qq[<a href="$MY_variables{script_name}?Operation=ItemSearch&amp;SearchIndex=$MY_variables{SearchIndex}&amp;$temp_Operation=$temp_search_string$Internal_variables{url_options}">$item</a>];
	}
	return $temp_list;
}

sub parse_blended {
	my $temp_input = shift;
	my %blended_searchindexes;
	my (@blended_item_array, $blended_asin, %blended_item_hash,$blended_html);
	@blended_item_array = @{${$temp_input}{Item}};
	foreach my $item (@blended_item_array) {
		$item =~ s/<ASIN>([^<]+)<\/ASIN>/$blended_item_hash{$1} = $item/e;
	}
	my $blended_level_2 = process_hashes_of_arrays($temp_input);
	$AWS_variables{TotalPages} = 0; $AWS_variables{TotalResults} = 0;
	foreach my $item (@{${$blended_level_2}{SearchIndex}}) {
		$item =~ s/<RelevanceRank>([^<]+)<\/RelevanceRank>/$blended_searchindexes{$1} = $item/e;
	}
	foreach my $key (sort {$a<=>$b} keys %blended_searchindexes ) {
		my (%exit_hash, $aws_indexname);
		delete $MY_variables{blended_IndexName}; delete $MY_variables{blended_Results}; delete $MY_variables{blended_see_more}; delete $MY_variables{products_html};
		$blended_searchindexes{$key} =~ s/<IndexName>([^<]+)<\/IndexName>/$aws_indexname = $1/e;
		if ($lookup_store{$aws_indexname}) {
			$MY_variables{blended_IndexName} = $lookup_store{$aws_indexname};
		} else {
			$MY_variables{blended_IndexName} = $aws_indexname;
		}
		$blended_searchindexes{$key} =~ s/<Results>([^<]+)<\/Results>/$MY_variables{blended_Results} = $1/e;
		$blended_searchindexes{$key} =~ s/<ASIN>([^<]+)<\/ASIN>/push @{$exit_hash{Item}},$blended_item_hash{$1}/ge;
		assign_variables("products",\%exit_hash);
		if ($MY_variables{blended_Results} > 3) { $MY_variables{blended_see_more} = qq[ <A href="$MY_variables{script_name}?Operation=ItemSearch&amp;Keywords=$Internal_variables{Keywords_encoded}&amp;SearchIndex=$aws_indexname$Internal_variables{url_options}">...$language_text{see_text6}</a>]; }
		$blended_html .= set_html("blended");
	}
	$MY_variables{products_html} = $blended_html;
	$MY_variables{SearchIndex} = "Blended"; build_search_box();
	return;
}

sub initialize_buttons {
	my $value = $_[0];
	my ($temp_button);
	if (!$MY_variables{associate_id}) { $Internal_variables{html}  = "<h1>No associate_id found!</h1>"; }
	if (!$AWS_variables{OfferListingId}) {
		$MY_variables{my_availability} = qq[];
		my $parent_location;
		if ($Internal_variables{session}) {
			$parent_location = "$MY_variables{script_name}?cart_action=get$Internal_variables{url_options}";
		} else {
			$parent_location = "#";
		}
		$temp_button = qq[<form><input class="apf_submit_button_style" type="button" value=" $language_text{button_text11} " onClick="parent.location='$parent_location';newwindow=window.open('$AWS_variables{DetailPageURL}','amznwin','location=yes,scrollbars=yes,status=yes,toolbar=yes,resizable=yes');if(window.focus){newwindow.focus()};" /></form>];
	} else {
		if ($value eq "buy") {
			$temp_button = qq[
				<form method="GET" action="http://www.$Internal_variables{amazon_wwwsite}/gp/aws/cart/add.html" target="amazon">
				<input type="hidden" name="SubscriptionId" value="$MY_variables{subscription_id}" />
				<input type="hidden" name="AssociateTag" value="$MY_variables{associate_id}" />
				<input type="hidden" name="OfferListingId.1" value="$AWS_variables{OfferListingId}" />
				<input type="hidden" name="Quantity.1" value="1" />
				<input class="apf_submit_button_style" type="submit" name="submit.add-to-cart" value="$language_text{button_text1}" />
				</form>
			];
		}
		if ($value eq "cart") {
			$temp_button = qq[
				<form name="addtocart" action="$MY_variables{script_name}" method="get">
				$MY_variables{form_options}
				<input type="hidden" name="cart_action" value="add" />
				<input type="hidden" name="OfferListingId_$AWS_variables{OfferListingId}" value="1" />
			];
			if ($FORM{ListItemId}) {
				$temp_button .= qq[	<input type="hidden" name="ListItemId" value="$FORM{ListItemId}_$AWS_variables{ASIN}" />\n];
			}
			$temp_button .= qq[
				<input class="apf_submit_button_style" type="submit" value="$language_text{button_text10}" />
				$MY_variables{form_options}
				</form>
			];
		}
	}
	return $temp_button;
}


sub apf_commands {
	my ($command_string, $lap, $whose_variables) = @_;
	$lap = $lap + 1;
	my (%COMMAND, $command_name, $command_value);
	$command_string =~ /<!--apf([^!]+?)!([^!]*?)!-->/s;
	my $command_commands = $1; my $command_html = $2;
	for my $command_pair (split(/&/, $command_commands)) {
		($command_name, $command_value) = split(/=/, $command_pair);
		if ($command_value eq "last") {
			if ($whose_variables eq "sellerprofile") { $command_value = $MY_variables{sellerprofile_max}; }
			elsif ($whose_variables eq "shopping_cart") { $command_value = $MY_variables{total_cart_items}; }
			elsif ($whose_variables eq "products" and $Internal_variables{details_max} < $FORM{max_results}) { $command_value = $Internal_variables{details_max}; }
			elsif ($whose_variables =~ "_menu") { $command_value = $Internal_variables{menu_length}; }
			else { $command_value = $FORM{max_results}; }
		}
		$COMMAND{$command_name} = $command_value;
	}
	if ($COMMAND{apf_end} and $lap > $COMMAND{apf_end}) { return; }
	if ($COMMAND{apf_repeat} and !$COMMAND{apf_start}) { $COMMAND{apf_start} = 1; }
	if ($COMMAND{apf_start}) {
		if ($COMMAND{apf_start} == $lap) { return $command_html; }
		if ($COMMAND{apf_repeat}) {
			my $test_lap = ($lap - $COMMAND{apf_start})/$COMMAND{apf_repeat};
			if ($test_lap == int $test_lap) { return $command_html;	}
		}
	}
	if ($COMMAND{apf_end} == $lap) {
		return $command_html;
	} elsif ($COMMAND{apf_include}) {
		if ($COMMAND{apf_include} eq "nav_menu") {
			if ($MY_variables{SearchIndex} and $FORM{SearchIndex} ne "Blended" and (!$Internal_variables{nav_menu_type} or $Internal_variables{nav_menu_type} eq "children")) {
				$debug .= "wait 1 second then get_node_children for nav_menu<br />\n";
				sleep 1;
				$MY_variables{nav_menu_html} = load_browse_table(get_node_children($current_base_nodes{$MY_variables{SearchIndex}},"nav_menu"), "SearchIndex=$MY_variables{SearchIndex}&amp;BrowseNode=", "nav_menu");
			} elsif ($Internal_variables{nav_menu_type}  ne "none") {
				$MY_variables{nav_menu_html} = load_browse_table(\%store_to_browse, "SearchIndex=", "nav_menu");
			}
			if ($MY_variables{nav_menu_html}) { return $command_html; }
		} else {
			my $include_variable;
			open(FILEHANDLE,"<$COMMAND{apf_include}");
			while (<FILEHANDLE>) { $include_variable = $include_variable . $_; }
			close (FILEHANDLE);
			return $include_variable;
		}
	} elsif ($COMMAND{apf_show_vars}) {
		my $temp_html;
		if ($COMMAND{apf_show_vars} ne "AWS") {
			$temp_html = "<br /><h1>MY_variables:</h1><br /><br />";
			foreach my $key (sort keys %MY_variables) {
				(my $encoded = $MY_variables{$key}) =~ s/</&lt;/g;
				$temp_html .= "<h3>&#37;%$key%%</h3> => $encoded<br /><br />";
			}
			$temp_html .= "<br /><br />";
		}
		if ($COMMAND{apf_show_vars} ne "MY") {
			$temp_html .= "<br /><h1>AWS_variables:</h1><br /><br />";
			foreach my $key (sort keys %AWS_variables) {
				(my $encoded = $AWS_variables{$key}) =~ s/</&lt;/g;
				$temp_html .= "<h3>&#37;%$key%%</h3> => $encoded<br /><br />";
			}
			$temp_html .= "<br /><br />";
		}
		return $temp_html . "<br /><br />";
	}
	return;
}

sub parse_xml_into_hashes_of_arrays {
	my $xml_result = shift;
	my (%temp_level_0);
	$xml_result =~ s/<([^>]+?)(?:\s[^>]+)?>(.*?)<\/\1>/push @{$temp_level_0{$1}}, $2;/gsie;
	my $temp_level_1 = process_hashes_of_arrays(\%temp_level_0);
	my $temp_level_2 = process_hashes_of_arrays($temp_level_1);
	$AWS_variables{TotalResults} = ${${$temp_level_2}{TotalResults}}[0];
	$AWS_variables{TotalPages} = ${${$temp_level_2}{TotalPages}}[0];
	return $temp_level_2;
}

sub process_hashes_of_arrays {
	my $entry_hash = shift;
	my %exit_hash;
	for my $key (keys %$entry_hash) {
		if (!${${$entry_hash}{$key}}[1] and $key ne "ItemSearchResponse") {
			$AWS_variables{$key} = ${${$entry_hash}{$key}}[0];
			if ($key eq "Title") { $AWS_variables{$key} = html_escape($AWS_variables{$key}); }
		}
 		foreach my $item (@{${$entry_hash}{$key}}) {
			$item =~ s/<([^\s>]+)(?:\sUnits="([^"]+)"+)?>(.*?)<\/\1>/my $units; if ($2) { $units = " $2"; } push @{$exit_hash{$1}}, "$3$units";/gsie;
		}
	}
	return \%exit_hash;
}

sub set_html {
	my ($temp_result, $lap);
	($Internal_variables{which}, $lap) = @_;
	my $this_function = "set_html_first";
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
	if ($template_html{$Internal_variables{which}}) {
		$temp_result = $template_html{$Internal_variables{which}};
	} else {
		my $template_file_name;
		if ($FORM{templates}) {
			$template_file_name = "$Internal_variables{templates_location}/" . $Internal_variables{which} . ".template";
			if (-e $template_file_name ne 1 ) { $template_file_name = "$Internal_variables{templates_directory}/default/" . $Internal_variables{which} . ".template"; }
		} else {
			$template_file_name = "$Internal_variables{templates_directory}/default/" . $Internal_variables{which} . ".template";
		}
		open(FILEHANDLE,"<$template_file_name");
		while (<FILEHANDLE>) { $template_html{$Internal_variables{which}} = $template_html{$Internal_variables{which}} . $_; }
		close (FILEHANDLE);
		$temp_result = $template_html{$Internal_variables{which}};
	}
	my $this_function = "set_html_second";
	foreach my $item (@mod_files) {
		my $hash_name = qq[subs__$item]; my $sub_name = $this_function . "__" . $item;
		if ($mod_use{$item} eq "Yes" and ${$hash_name}{$this_function} eq "Yes") { &{$sub_name}; }
	}
	$MY_variables{result_number} = $lap + 1 + (($Internal_variables{current_page} - 1) * $Internal_variables{results_per_page});
	$temp_result =~ s/%%(\w+)%%/if ($AWS_variables{$1}) { $AWS_variables{$1}; } elsif ($MY_variables{$1}) { $MY_variables{$1}; } elsif ($language_text{$1}) { $language_text{$1}; } else { "%%$1%%"; }/ge;
	$temp_result =~ s/(<!--apf[^!]+?![^!]*?!-->)/apf_commands($1,$lap,$Internal_variables{which});/egs;
	$temp_result =~ s/%%(\w+)%%/if ($AWS_variables{$1}) { $AWS_variables{$1}; } elsif ($MY_variables{$1}) { $MY_variables{$1}; } else { $language_text{$1}; }/ge;
	if ($Internal_variables{which} eq "item" and $temp_result =~ /$language_text{button_text10}/ and $temp_result =~ /$language_text{cart_text4}/) {
		$temp_result =~ s/"$language_text{button_text10}"\s\/><\/form>/"$language_text{button_text10}" \/>/;
		$temp_result =~ s/(<form\sname="addtocart"[^>]+>)//;
		$temp_result = $1 . $temp_result . qq[\n</form>];
	}
	return $temp_result;
}

1;

