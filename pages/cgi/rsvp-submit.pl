#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use Fcntl qw(:flock);

my $DATA_DIR = '/var/www/ordiwedding/-/rsvp-data';
my $NAV_FILE = '/var/www/ordiwedding/-/nav.html';

my $q = CGI->new;

# --- Helpers ---

sub sanitize {
    my ($str, $maxlen) = @_;
    $str =~ s/<[^>]*>//g;
    $str =~ s/^\s+|\s+$//g;
    $str = substr($str, 0, $maxlen) if length($str) > $maxlen;
    return $str;
}

sub escape_html {
    my ($str) = @_;
    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/"/&quot;/g;
    return $str;
}

sub sanitize_for_filename {
    my ($str) = @_;
    $str = lc($str);
    $str =~ s/[^a-z0-9]+/_/g;
    $str =~ s/^_|_$//g;
    $str = substr($str, 0, 50);
    return $str;
}

sub read_nav {
    my $html = '';
    if (open my $fh, '<', $NAV_FILE) {
        local $/;
        $html = <$fh>;
        close $fh;
    }
    return $html;
}

sub html_page {
    my ($title, $body) = @_;
    my $nav = read_nav();
    print $q->header('text/html');
    print <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$title - Julie &amp; Anthony</title>
    <link rel="stylesheet" href="/-/style.css">
</head>
<body>
    <nav>$nav</nav>
    $body
    <footer>
        <p>Questions? Contact <a href="mailto:julie.dawson\@gmail.com">Julie</a>
        or <a href="mailto:mail\@anthonybailey.net">Anthony</a></p>
    </footer>
</body>
</html>
HTML
}

# --- Parse and validate ---

my $name      = sanitize($q->param('name')      || '', 200);
my $contact   = sanitize($q->param('contact')   || '', 200);
my $attending  = sanitize($q->param('attending') || '', 20);
my $number    = int($q->param('number') || 1);
my $guests    = sanitize($q->param('guests')    || '', 500);
my $dietary   = sanitize($q->param('dietary')   || '', 2000);
my $message   = sanitize($q->param('message')   || '', 2000);

$number = 1  if $number < 1;
$number = 20 if $number > 20;

my @errors;
push @errors, 'Please enter your name.'                       unless $name;
push @errors, 'Please enter your email or phone number.'      unless $contact;
push @errors, 'Please select whether you will be attending.'  unless $attending =~ /^(yes|no|maybe)$/;

if (@errors) {
    my $list = join "\n", map { "        <li>" . escape_html($_) . "</li>" } @errors;
    html_page('RSVP - Error', <<"BODY");
    <h1>Something's not quite right</h1>
    <ul>
$list
    </ul>
    <p><a href="/-/rsvp">Go back and try again</a></p>
BODY
    exit;
}

# --- Check data directory ---

unless (-d $DATA_DIR && -w $DATA_DIR) {
    html_page('RSVP - Error', <<"BODY");
    <h1>Sorry, something went wrong</h1>
    <p>We couldn't save your RSVP right now. Please email
    <a href="mailto:julie.dawson\@gmail.com">Julie</a> instead.</p>
BODY
    exit;
}

# --- Build filename ---

my $name_part = sanitize_for_filename($name);
my @all_names = ($name_part);
if ($guests && $attending ne 'no') {
    for my $g (split /\s*[,&]\s*|\s+and\s+/i, $guests) {
        my $s = sanitize_for_filename($g);
        push @all_names, $s if $s;
    }
}
my $names_joined = join('+', @all_names);
$names_joined = substr($names_joined, 0, 100) if length($names_joined) > 100;

my $num_str  = ($attending eq 'no') ? 0 : $number;
my $filename = "$attending-$num_str-$names_joined.txt";

# --- Archive any previous submission with same contact ---

my $contact_lower = lc($contact);
my @to_archive;

if (opendir my $dh, $DATA_DIR) {
    while (my $entry = readdir $dh) {
        next unless $entry =~ /\.txt$/;
        next if $entry =~ /^\d{8}-\d{6}\./;  # already archived
        my $path = "$DATA_DIR/$entry";
        if (open my $fh, '<', $path) {
            while (my $line = <$fh>) {
                if ($line =~ /^Contact:\s*(.+)/) {
                    my $existing = $1;
                    $existing =~ s/\s+$//;
                    push @to_archive, $entry if lc($existing) eq $contact_lower;
                    last;
                }
            }
            close $fh;
        }
    }
    closedir $dh;
}

my @now = localtime();
my $timestamp = sprintf('%04d%02d%02d-%02d%02d%02d',
    $now[5]+1900, $now[4]+1, $now[3], $now[2], $now[1], $now[0]);

for my $old (@to_archive) {
    rename "$DATA_DIR/$old", "$DATA_DIR/$timestamp.$old";
}

# --- Write submission ---

my $date_str = sprintf('%04d-%02d-%02d %02d:%02d:%02d',
    $now[5]+1900, $now[4]+1, $now[3], $now[2], $now[1], $now[0]);

my $content = "Date: $date_str\n";
$content   .= "Name: $name\n";
$content   .= "Contact: $contact\n";
$content   .= "Attending: $attending\n";
if ($attending ne 'no') {
    $content .= "Number: $number\n";
    $content .= "Additional guests: $guests\n" if $guests;
    $content .= "Dietary: $dietary\n"          if $dietary;
}
$content .= "Message: $message\n" if $message;

my $filepath = "$DATA_DIR/$filename";
open(my $fh, '>', $filepath) or do {
    html_page('RSVP - Error', <<"BODY");
    <h1>Sorry, something went wrong</h1>
    <p>We couldn't save your RSVP right now. Please email
    <a href="mailto:julie.dawson\@gmail.com">Julie</a> instead.</p>
BODY
    exit;
};
flock($fh, LOCK_EX);
print $fh $content;
close $fh;

# --- Thank-you page ---

my $esc_name    = escape_html($name);
my $esc_contact = escape_html($contact);
my $esc_guests  = escape_html($guests);
my $esc_dietary = escape_html($dietary);
my $esc_message = escape_html($message);

my $updated = @to_archive
    ? '<p>Your previous RSVP has been updated.</p>'
    : '';

my $summary = "<p><strong>Name:</strong> $esc_name</p>\n";
$summary   .= "<p><strong>Contact:</strong> $esc_contact</p>\n";

if ($attending eq 'yes') {
    $summary .= "<p><strong>Attending:</strong> Yes</p>\n";
    $summary .= "<p><strong>Party size:</strong> $number</p>\n";
    $summary .= "<p><strong>Additional guests:</strong> $esc_guests</p>\n" if $guests;
    $summary .= "<p><strong>Dietary:</strong> $esc_dietary</p>\n"          if $dietary;
} elsif ($attending eq 'no') {
    $summary .= "<p><strong>Attending:</strong> No</p>\n";
} else {
    $summary .= "<p><strong>Attending:</strong> Not sure yet</p>\n";
    $summary .= "<p><strong>Party size:</strong> $number</p>\n";
    $summary .= "<p><strong>Additional guests:</strong> $esc_guests</p>\n" if $guests;
    $summary .= "<p><strong>Dietary:</strong> $esc_dietary</p>\n"          if $dietary;
}
$summary .= "<p><strong>Message:</strong> $esc_message</p>\n" if $message;

html_page('Thank You', <<"BODY");
    <h1>Thank you, $esc_name!</h1>
    $updated
    <h2>Your RSVP</h2>
    $summary
    <p>You can update your RSVP anytime by
    <a href="/-/rsvp">submitting the form again</a>
    with the same email or phone number.</p>
BODY
