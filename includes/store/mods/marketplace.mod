#	version:		1.050627
# copyright:	MrRat - http://www.mrrat.com
# license:		GPL - http://www.opensource.org/licenses/gpl-license.html
# purpose:		mod for APF
# description:	support for marketplace items
#
use strict vars;

my ($my_marketplace_text, $my_ThirdPartyProductDetails);
our %subs__marketplace = ( load_language => "Yes", initialize_hashes => "Yes", calculate_initial_variables => "Yes", build_products__main => "Yes", assign_variables_Details_loop => "Yes" );

sub load_language__marketplace {
	$language_text{my_marketplace1} = "Price:";
	$language_text{my_marketplace2} = "Used";
	$language_text{my_marketplace3} = "Collectible";
	$language_text{my_marketplace4} = "Third Party New";
	$language_text{my_marketplace5} = "Refurbished";
	$language_text{thirdparty_text1} = "Seller:";
	$language_text{thirdparty_text2} = "Condition:";
	$language_text{thirdparty_text3} = "Condition Type:";
	$language_text{thirdparty_text4} = "From:";
	$language_text{thirdparty_text5} = "Comments:";
	$language_text{thirdparty_text6} = "Quantity:";
	$language_text{thirdparty_text7} = "Offering Type:";
	$language_text{thirdparty_text8} = "End Date:";
	$language_text{thirdparty_text9} = "Total Feedback:";
	$language_text{thirdparty_text10} = "Cancelled Auctions:";
	$language_text{thirdparty_text11} = "Date:";
	$language_text{thirdparty_text12} = "SubCondition:";
	$language_text{searchbox_text20} = "third-party ASIN"; 
	$language_text{searchbox_text21} = "Third-party exchange ID";
	$language_text{searchbox_text22} = "Third-party Seller ID";
}

#	$language_text{my_marketplace1} = "Preis:";
#	$language_text{my_marketplace2} = "Gebraucht";
#	$language_text{my_marketplace3} = "Sammler";
#	$language_text{my_marketplace4} = "Neu bei anderem Anbieter";
#	$language_text{my_marketplace5} = "&Uuml;berholt";
#	$language_text{thirdparty_text1} = "Verk&auml;fer:";
#	$language_text{thirdparty_text2} = "Zustand:";
#	$language_text{thirdparty_text3} = "Zustandsart:";
#	$language_text{thirdparty_text4} = "von:";
#	$language_text{thirdparty_text5} = "Kommentare:";
#	$language_text{thirdparty_text6} = "Menge:";
#	$language_text{thirdparty_text7} = "Angebots-Typ:";
#	$language_text{thirdparty_text8} = "End-Datum:";
#	$language_text{thirdparty_text9} = "Kommentare insgesamt:";
#	$language_text{thirdparty_text10} = "Gel&ouml;schte Auktionen:";
#	$language_text{thirdparty_text11} = "Datum:";

sub initialize_hashes__marketplace {
	our %offering_type = ( new => "ThirdPartyNew", used => "Used", collectible => "Collectible", refurbished => "Refurbished" );
}

sub calculate_initial_variables__marketplace {
	if ($FORM{IdType}) {
		$Internal_variables{see_url_options} .= "&amp;IdType=$FORM{IdType}";
		$Internal_variables{more_form_options} .= qq[<input type="hidden" name="IdType" value="$FORM{IdType}" />];
		$Internal_variables{query} .= "&IdType=$FORM{IdType}";
	}
	if ($FORM{Id}) {
		$Internal_variables{see_url_options} .= "&amp;Id=$FORM{Id}";
		$Internal_variables{more_form_options} .= qq[<input type="hidden" name="Id" value="$FORM{Id}" />];
		$Internal_variables{query} .= "&Id=$FORM{Id}";
	}
	if ($FORM{SellerId}) {
		$Internal_variables{see_url_options} .= "&amp;SellerId=$FORM{SellerId}";
		$Internal_variables{more_form_options} .= qq[<input type="hidden" name="SellerId" value="$FORM{SellerId}" />];
		$Internal_variables{query} .= "&SellerId=$FORM{SellerId}";
	}
}

sub build_products__main__marketplace {
	if ($FORM{myOperation} =~ /(New|Used|Collectible|Refurbished)/) {
		my %marketplace_text_hash = ( Used => $language_text{my_marketplace2}, Collectible => $language_text{my_marketplace3}, New => $language_text{my_marketplace4}, Refurbished => $language_text{my_marketplace5} );
		$my_marketplace_text = $marketplace_text_hash{$FORM{myOperation}};
		my $query = "&Operation=ItemLookup&ItemId=$FORM{ItemId}&Condition=$FORM{myOperation}&MerchantId=All&ResponseGroup=$Internal_variables{ResponseGroup_Products}";
		if ($FORM{ItemPage} ne "1") { $query .= qq[&OfferPage=$FORM{ItemPage}]; }
		my $this_xml_url = $Internal_variables{base_url} . $query;
		my $xml_result = get_url($this_xml_url);
		my $level_1 = parse_xml_into_hashes_of_arrays($xml_result);
		assign_variables("products",$level_1);
		return "found";
	} elsif ($FORM{myOperation} =~ m/SellerListing/) {
		my @temp_array;
		my $whatever = build_sellerlookup();
		my $this_xml_url = $Internal_variables{base_url} . "&Operation=$FORM{myOperation}" . $Internal_variables{query} . "&ResponseGroup=SellerListing";
		$debug .= "wait 1 second then get SellerListing<br />\n";
		sleep 1;
		my $xml_result = get_url($this_xml_url);
		$xml_result =~ s/<SellerListing>(.*?)<\/SellerListing>/push @temp_array, $1;/gsie;
		$MY_variables{products_html} .= $whatever . parse_thirdpartyhash(\@temp_array,"sellersearch");
		return "found";
	}
}

sub assign_variables_Details_loop__marketplace {
	my $level_3 = shift;
	my $temp_price;
	if ($FORM{Operation} eq "ItemLookup" and ($MY_variables{current_locale} ne "us")) {
		my $marketplace_result_xml_url = $Internal_variables{base_url} . "&Operation=ItemLookup&ItemId=$FORM{ItemId}&ResponseGroup=OfferSummary&MerchantId=All";
		$debug .= "wait 1 second then get non_us_marketplace_result<br />\n";
		sleep 1;
		my $non_us_marketplace_result = get_url($marketplace_result_xml_url);
		$non_us_marketplace_result =~ s/<LowestUsedPrice>(.*?)<\/LowestUsedPrice>/$AWS_variables{LowestUsedPrice} = $1;/e;
		$non_us_marketplace_result =~ s/<LowestCollectiblePrice>(.*?)<\/LowestCollectiblePrice>/$AWS_variables{LowestCollectiblePrice} = $1;/e;
		$non_us_marketplace_result =~ s/<LowestNewPrice>(.*?)<\/LowestNewPrice>/$AWS_variables{LowestNewPrice} = $1;/e;
		$non_us_marketplace_result =~ s/<LowestRefurbishedPrice>(.*?)<\/LowestRefurbishedPrice>/$AWS_variables{LowestRefurbishedPrice} = $1;/e;
	}
	if ($Internal_variables{merchants} and $AWS_variables{TotalNew} eq "1" and $AWS_variables{TotalOffers} eq "1") { return; }
	if ($AWS_variables{LowestUsedPrice}) {
		$AWS_variables{LowestUsedPrice} =~ s/<FormattedPrice>([^<]+)<\/FormattedPrice>/$temp_price = $1/e;
		$MY_variables{my_used} = qq[<a href="$MY_variables{script_name}?myOperation=Used&amp;ItemId=$AWS_variables{ASIN}$Internal_variables{url_options}">$language_text{my_marketplace2} $language_text{my_marketplace1} $temp_price</a><br />];
	}
	if ($AWS_variables{LowestCollectiblePrice}) {
		$AWS_variables{LowestCollectiblePrice} =~ s/<FormattedPrice>([^<]+)<\/FormattedPrice>/$temp_price = $1/e;
		$MY_variables{my_collectible} = qq[<a href="$MY_variables{script_name}?myOperation=Collectible&amp;ItemId=$AWS_variables{ASIN}$Internal_variables{url_options}">$language_text{my_marketplace3} $language_text{my_marketplace1} $temp_price</a><br />];
	}
	if ($AWS_variables{LowestNewPrice}) {
		$AWS_variables{LowestNewPrice} =~ s/<FormattedPrice>([^<]+)<\/FormattedPrice>/$temp_price = $1/e;
		$MY_variables{my_thirdpartynew} = qq[<a href="$MY_variables{script_name}?myOperation=New&amp;ItemId=$AWS_variables{ASIN}$Internal_variables{url_options}">$language_text{my_marketplace4} $language_text{my_marketplace1} $temp_price</a><br />];
	}
	if ($AWS_variables{LowestRefurbishedPrice}) {
		$AWS_variables{LowestRefurbishedPrice} =~ s/<FormattedPrice>([^<]+)<\/FormattedPrice>/$temp_price = $1/e;
		$MY_variables{my_refurbished} = qq[<a href="$MY_variables{script_name}?myOperation=Refurbished&amp;ItemId=$AWS_variables{ASIN}$Internal_variables{url_options}">$language_text{my_marketplace5} $language_text{my_marketplace1} $temp_price</a><br />];
	}
	if ($my_marketplace_text) {
		my ($ii,@temp_array);
		$AWS_variables{Offers} =~ s/<TotalOffers>(.*?)<\/TotalOffers>/$AWS_variables{TotalResults} = $1/e;
		$AWS_variables{Offers} =~ s/<TotalOfferPages>(.*?)<\/TotalOfferPages>/$AWS_variables{TotalPages} = $1/e;
		see_more();
		$AWS_variables{Offers} =~ s/<Offer>(.*?)<\/Offer>/push @temp_array, $1;/gsie;
		$my_ThirdPartyProductDetails = parse_thirdpartyhash(\@temp_array,"thirdparty_products");
		$MY_variables{store} = $my_marketplace_text; $MY_variables{subject} = $AWS_variables{Title};
		return $my_ThirdPartyProductDetails;
	}
}

sub build_sellerlookup {
	my (@temp_array,$ii,$my_sellerlookupDetails);
	my $query = "&Operation=SellerLookup&SellerId=$FORM{SellerId}&ResponseGroup=Seller";
	if ($FORM{ItemPage} ne "1") { $query .= qq[&FeedbackPage=$FORM{ItemPage}]; }
	my $this_xml_url = $Internal_variables{base_url} . $query;
	my $xml_result = get_url($this_xml_url);
	$xml_result =~ s|<AverageFeedbackRating>([^<]+)</AverageFeedbackRating>|$MY_variables{SellerRating} = $1|e;
	if (!$MY_variables{SellerRating}) { $MY_variables{SellerRating} = "$language_text{average_rating_text2}"; }
	$xml_result =~ s|<Nickname>([^<]+)</Nickname>|$MY_variables{SellerNickname} = $1|e;
	$xml_result =~ s|<SellerName>([^<]+)</SellerName>|$MY_variables{SellerNickname} = $1|e;
	$MY_variables{store} = $MY_variables{SellerNickname}; $MY_variables{subject} = $language_text{button_text4};
	$xml_result =~ s|<TotalFeedback>([^<]+)</TotalFeedback>|$MY_variables{TotalFeedback} = $1|e;
	$xml_result =~ s|<Feedback>(.*?)<\/Feedback>|push @temp_array, $1;|gse;
	$xml_result =~ s|<About>(.*?)</About>|$MY_variables{SellerAbout} = $1|se;
	$MY_variables{SellerAbout} =~ s/!/./g;
	$MY_variables{SellerAbout} =~ s/<[^>]+>/ /gs;
	$MY_variables{OverallFeedbackRating} = $MY_variables{SellerRating};
	$MY_variables{NumberOfFeedback} = $MY_variables{TotalFeedback};
	$MY_variables{sellerprofile_max} = $#{@temp_array} + 1;
	foreach my $item (@temp_array) {
		$item =~ s|<Rating>([^<]+)</Rating>|$MY_variables{FeedbackRating} = $1|e;
		$item =~ s|<Comment>([^<]+)</Comment>|$MY_variables{FeedbackComment} = $1|e;
		$item =~ s|<Date>([^<]+)</Date>|$MY_variables{FeedbackDate} = $1|e;
		$my_sellerlookupDetails .= set_html("sellerprofile",$ii);
		$ii++;
		delete $MY_variables{FeedbackRating}; delete $MY_variables{FeedbackComment}; delete $MY_variables{FeedbackDate};
	}
	delete $MY_variables{SellerRating}; delete $MY_variables{SellerRating}; delete $MY_variables{SellerNickname}; delete $MY_variables{TotalFeedback};
	return $my_sellerlookupDetails;
}

sub parse_thirdpartyhash {
	my ($temp_array, $whose) = @_;
	my (%thirdpartyhash,$ii,$my_ThirdPartyProductDetails);
	foreach my $item (@{$temp_array}) {
		foreach my $key (keys %thirdpartyhash) {
			delete $MY_variables{$key};
			delete $thirdpartyhash{$key};
		}
		if ($item =~ m|<Name>Amazon\.|) { next; }
		$item =~ s|<FormattedPrice>([^<]+)</FormattedPrice>|$thirdpartyhash{OfferingPrice} = $1|e;
		if (!$thirdpartyhash{OfferingPrice}) { next; }
		$thirdpartyhash{Asin} = $AWS_variables{Asin};
		$item =~ s|<AverageFeedbackRating>([^<]+)</AverageFeedbackRating>|$thirdpartyhash{SellerRating} = $1|e;
		if (!$thirdpartyhash{SellerRating}) { $thirdpartyhash{SellerRating} = "$language_text{average_rating_text2}"; }
		$item =~ s|<Nickname>([^<]+)</Nickname>|$thirdpartyhash{SellerNickname} = $1|e;
		$item =~ s|<SellerName>([^<]+)</SellerName>|$thirdpartyhash{SellerNickname} = $1|e;
		$item =~ s|<Name>([^<]+)</Name>|$thirdpartyhash{MerchantName} = $1|e;
		if (!$thirdpartyhash{SellerNickname} and $thirdpartyhash{MerchantName}) { $thirdpartyhash{SellerNickname} = $thirdpartyhash{MerchantName}; }
		if (!$thirdpartyhash{SellerNickname}) { $thirdpartyhash{SellerNickname} = "$language_text{average_rating_text2}"; }
		$item =~ s|<Condition>([^<]+)</Condition>|$thirdpartyhash{Condition} = $1|e;
		$item =~ s|<SubCondition>([^<]+)</SubCondition>|$thirdpartyhash{SubCondition} = $1|e;
		$item =~ s|<ConditionNote>([^<]+)</ConditionNote>|$thirdpartyhash{ConditionNote} = $1|e;
		$item =~ s|<Availability>([^<]+)</Availability>|$thirdpartyhash{ExchangeAvailability} = $1|e;
		$item =~ s|<State>([^<]+)</State>|$thirdpartyhash{SellerState} = $1|e;
		$item =~ s|<Country>([^<]+)</Country>|$thirdpartyhash{SellerCountry} = $1|e;
		$item =~ s|<ShipComments>([^<]+)</ShipComments>|$thirdpartyhash{ShipComments} = $1|e;
		$item =~ s|<SellerId>([^<]+)</SellerId>|$thirdpartyhash{SellerId} = $1|e;
		$item =~ s|<MerchantId>([^<]+)</MerchantId>|$thirdpartyhash{MerchantId} = $1|e;
		if (!$thirdpartyhash{SellerId} and $thirdpartyhash{MerchantId}) { $thirdpartyhash{SellerId} = $thirdpartyhash{MerchantId}; }
		$item =~ s|<ExchangeId>([^<]+)</ExchangeId>|$thirdpartyhash{ExchangeId} = $1|e;
		$item =~ s|<OfferListingId>([^<]+)</OfferListingId>|$thirdpartyhash{OfferListingId} = $1|e;
		$item =~ s|<Title>([^<]+)</Title>|$thirdpartyhash{ExchangeTitle} = $1|e;
		$item =~ s|<EndDate>([^<]+)</EndDate>|$thirdpartyhash{ExchangeEndDate} = $1|e;
		$item =~ s|<ASIN>([^<]+)</ASIN>|$thirdpartyhash{Asin} = $1|e;
		$item =~ s|<Quantity>([^<]+)</Quantity>|$thirdpartyhash{Quantity} = $1|e;
		$item =~ s|<QuantityAllocated>([^<]+)</QuantityAllocated>|$thirdpartyhash{QuantityAllocated} = $1|e;
		$thirdpartyhash{ExchangeQuantity} = $thirdpartyhash{Quantity} - $thirdpartyhash{QuantityAllocated};
		$thirdpartyhash{sellersearch_url} = "$MY_variables{script_name}?myOperation=SellerListingSearch&amp;SellerId=$thirdpartyhash{SellerId}$Internal_variables{url_options}";
		$thirdpartyhash{ExchangeItemUrl} = "$MY_variables{script_name}?myOperation=" . ucfirst($thirdpartyhash{Condition}) . "&amp;ItemId=$thirdpartyhash{Asin}$Internal_variables{url_options}";
		if ($thirdpartyhash{Asin}) {
			if ($MY_variables{current_locale} eq "us") {
				$AWS_variables{DetailPageURL} = "http://www.amazon.com/gp/redirect.html?tag=$MY_variables{associate_id}&location=/exec/obidos/ASIN/$thirdpartyhash{Asin}%3FSubscriptionId=$MY_variables{subscription_id}";
			} else {
				$AWS_variables{DetailPageURL} = "http://www.$Internal_variables{amazon_site}/exec/obidos/ASIN/$thirdpartyhash{Asin}/$MY_variables{associate_id}?SubscriptionId=$MY_variables{subscription_id}";
			}
		}
		foreach my $key (keys %thirdpartyhash) { $MY_variables{$key} = $thirdpartyhash{$key}; }
		$MY_variables{ShipComments} = $thirdpartyhash{ConditionNote};
		$MY_variables{ConditionType} = $thirdpartyhash{SubCondition};
		$MY_variables{ExchangeOfferingType} = $thirdpartyhash{Condition};
		$MY_variables{ExchangeConditionType} = $thirdpartyhash{SubCondition};
		$MY_variables{ExchangeSellerState} = $thirdpartyhash{SellerState};
		$MY_variables{ExchangeSellerCountry} = $thirdpartyhash{SellerCountry};
		$MY_variables{ExchangePrice} = $thirdpartyhash{OfferingPrice};
		$AWS_variables{OfferListingId} = $thirdpartyhash{OfferListingId};
		$MY_variables{buy_button} = initialize_buttons("buy");
		$MY_variables{shopping_cart_button} = initialize_buttons("cart");
		$my_ThirdPartyProductDetails .= set_html($whose,$ii);
		delete $AWS_variables{OfferListingId};
		$ii++;
	}
	return $my_ThirdPartyProductDetails;
}

