#!/usr/bin/perl -w
# ----------------------------------------------------------------------------
# Copyright (C) 2012 by Jake Cunningham.  All rights reserved
# This program is free software; you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by the 
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
# for more details.
#
# You should have received a copy of the GNU General Public License along 
# with this program; if not, write to the Free Software Foundation, Inc., 
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR ANY PARTICULAR PURPOSE.
# IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, OR PROFITS OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#----------------------------------------------------------------------------\
# http://jafat.sourceforge.net
# Jake Cunningham
# 11/10/2012
#


use IO::File;
use Getopt::Long;
use POSIX;

GetOptions ("debug"  => \$debug);
$VERSION = "1.1";
#------------------------------------------------------------------------\
if (!defined $ARGV[0] ) { print_usage() };

open(COOKIE, "$ARGV[0]") or die "Can't open $ARGV[0]\n";
binmode COOKIE; 

# Read Header
# 
read(COOKIE,$buffer,4);
$output = unpack("A*",$buffer);
$output =~ /^cook$/ || die "The input file does not appear to be a binary cookie file\n";

#------------------------------------------------------------------------\
# Number of pages

read(COOKIE,$recs,4);
$pages = unpack("H*",$recs);
$pages = hex($pages); # Convert it to Decimal
if ($debug) { print "DEBUG: Total Pages in file: $pages\n"; }

if ($debug) {
	$foo = tell(COOKIE);
	print "DEBUG: Loc:$foo\n";
}

for ($count = $pages; $count >= 1; $count--) {
	# size of page
	read(COOKIE,$buf,4);
	$pagesize = unpack("H*",$buf);
 	if ($debug) { print "$count\n Page Size: $pagesize\n"; }
	# Maybe do a pagesize hash here if we need it later
}

#print "URL\tName\tCreated\tExpires\tPath\tContents\n";
print "Path\tDomain\tCreated\tExpires\tValue\tName\n";

#-----------------------------------------------------------------------\
#The format for each page is as follows.
#    * The page section is in little endian format.
#    * The first four bytes is the page tag which is "0x00000100"

# This loop iterates over each page in the file
for ($page_count = $pages; $page_count >= 1; $page_count--) {

 	if ($debug) { print "----------Page info-------\n"; }

	read(COOKIE,$buf,4);
	$pagetag = unpack("H*",$buf);
	if ($debug) { print "DEBUG: Pagetag: $pagetag\n"; }

#
#   * The next four bytes are the number of cookies in that page. This is an integer number.

	read(COOKIE,$buf,4);
	$num_cookies = unpack("H*",$buf);
	$num_cookies = reverse_hex($num_cookies);

        #Modified for v1.1- This is a DEC instead of HEX
        $num_cookies = $num_cookies = hex($num_cookies);

	if ($debug) { 
		print "DEBUG: Cookies in page: $num_cookies\n";
		$foo = tell(COOKIE);
		$foo = sprintf("%x",$foo);
		print "DEBUG: Cookie num Loc. Hex:$foo\n";
	}

#  * Following that integer there is a four byte integer for each cookie. This integer specifies the start of the cookie in bytes from the start of the page.

for ($count = $num_cookies; $count >= 1; $count--) {
		read(COOKIE,$buf,4);
		$cookie_offset = unpack("H*",$buf);
		$cookie_offset = reverse_hex($cookie_offset);
		if ($debug) { print "DEBUG:Cookie#:$count at Offset:$cookie_offset\n";}
	}



#  * To close off the page header are four bytes of  zero, ie.  "0x00000000"

	read(COOKIE,$buf,4);
	$header_end = unpack("H*",$buf);
	$header_end =~ /00000000/ || die "Invalid page header ending: $header_end - Should be 0x00000000\n"; 
	if ($debug) { print "Header End: $header_end\n"; }

	$cookie_loc = tell(COOKIE);

        if ($debug) { print "Cookie Location: $cookie_loc\n"; }
	read_cookies($num_cookies, $cookie_loc);

} #End of the page loop

#---------------------------------------------------------------------------\
# This is the Cookie 
#---------------------------------------------------------------------------\

sub read_cookies {

   my ($tmp_num_cookies, $tmp_cookie_loc) = @_;

   seek(COOKIE,$tmp_cookie_loc,0) || die "Can't seek to $tmp_cookie_loc\n";

# Loop over Cookies in this page


for ($count = $tmp_num_cookies; $count >= 1; $count--) {
	#print "\n\n";
	if ($debug) {print "---------- Cookie Contents ------------------\n";}

	# Size of Cookie
	read(COOKIE,$buf,8);
	$csize = unpack("h*",$buf);
	$csize = reverse_hex($csize);
	if ($debug) { print "C SIZE:$csize\n"; }

	# Cookie Flags
	read(COOKIE,$buf,8);
	$cflags= unpack("h*",$buf);
	$cflags = reverse_hex($cflags);
	if ($debug) { print "C FLags:$cflags\n"; }

	$curr_loc = tell(COOKIE);

	if ($debug) {
		print "DEBUG: LocDec: $curr_loc\n";
        	print"DEBUG: LocHex: ". sprintf("%x",$curr_loc) . "\n";
	}

	# Skip these 16 bytes for now
	read(COOKIE,$buf,16);
	$bytes_skipped = unpack("H*",$buf);
	if ($debug) { print "Bytes Skipped: $bytes_skipped\n"; }

	# End of cookie header tag (all 0)
	read(COOKIE,$buf,8);
	$cheader_end = unpack("H*",$buf);
	if ($debug) { print "C HEADER END: $cheader_end\n"; }
	# Put some logic here to verify it is all 0s and error if not

	# Expiry date
	read(COOKIE,$buf,8);
	# It's a double....
	$cexpiry = unpack("d*",$buf);
	$cexpiry = convert_time($cexpiry);
	#print "Expire Date: $cexpiry\n";

	$curr_loc = tell(COOKIE);

	if ($debug) {
		print "DEBUG: LocDec: $curr_loc\n";
        	print"DEBUG: LocHex: ". sprintf("%x",$curr_loc) . "\n";
	}

	# Last Access Time
	read(COOKIE,$buf,8);
	# It's a double....
	$c_lastaccess = unpack("d*",$buf);
	$c_lastaccess = convert_time($c_lastaccess);
	#print "Last Access: $c_lastaccess\n";

	$curr_loc = tell(COOKIE);

	if ($debug) { 
		print "DEBUG: LocDec: $curr_loc\n";
        	print"DEBUG: LocHex: ". sprintf("%x",$curr_loc) . "\n";
	}

	$name_prop = read_null_term($curr_loc);
	#print "Name: $name_prop\n";

	$curr_loc = tell(COOKIE);

	if ($debug) { 
		print "DEBUG: LocDec: $curr_loc\n";
        	print"DEBUG: LocHex: ". sprintf("%x",$curr_loc) . "\n";
	}

	$val_prop = read_null_term($curr_loc);
	#print "Value: $val_prop\n";

	$curr_loc = tell(COOKIE);
	$url_prop = read_null_term($curr_loc);
	#print "URL: $url_prop\n";

	$curr_loc = tell(COOKIE);
	$path_prop = read_null_term($curr_loc);
	#print "PATH: $path_prop\n";
	
	print "$url_prop\t$name_prop\t$c_lastaccess\t$cexpiry\t$path_prop\t$val_prop\n";

 	undef $cexpiry;
	undef $c_lastaccess;
	undef $url_prop;
	undef $path_prop;
	undef $val_prop;
}
}
#---------------------------------------------------------------------------\
# Read a null terminated string from the specified location.

sub read_null_term {
    my ($loc) = shift;
    #Save old record seperator
    my $old_rs = $/;
    # Set new seperator to NULL term.
    $/ = "\0";
    seek(COOKIE, $loc,0) or die "Can't seek to $loc\n";
    my $term_data = <COOKIE>;
    chomp($term_data);
    # Reset 
    $/ = $old_rs;
    return($term_data);
}
#---------------------------------------------------------------------------\
# CHange this to be 4 or 8 bytes reversed
sub reverse_hex {

 my $HEXDATE = shift;
 my @bytearry=();
 my $byte_cnt = 0;
 my $max_byte_cnt = 4;
 my $byte_offset = 0;
 while($byte_cnt < $max_byte_cnt) {
    my $tmp_str = substr($HEXDATE,$byte_offset,2);
    push(@bytearry,$tmp_str);
   $byte_cnt++;
   $byte_offset+=2;
 }
   return join('',reverse(@bytearry));
}
#---------------------------------------------------------------------------\
sub convert_time {

   # Windows Perl epoch 1/1/1970 0:0:0 UTC so difference is 978307200
    my $bin_val = shift;

    my ($fsec,$iVal) = POSIX::modf($bin_val);

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(978307200+$iVal);

    my $new_date = sprintf("%04d-%02d-%02dT%02d:%02d:%.6fZ", $year+1900,$mon+1,$mday,$hour,$min,$sec+$fsec);

    return($new_date);

}

#---------------------------------------------------------------------------\
sub print_usage {
	print "\nSafari Binary Cookie Parser $VERSION\n";
	print "Copyright 2012 - Jake Cunningham\n";
	print "Distributed using GNU GPL v3.0\n";
	print "Usage:\n";
	print "\t $0 Cookies.Binarycookie\n\n";
	exit;
}
#---------------------------------------------------------------------------\
