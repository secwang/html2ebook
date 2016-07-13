#!/usr/local/bin/perl

sub shell ($);
opendir(DH, $ARGV[0]);
my @files = readdir(DH);
closedir(DH);

foreach my $file (@files)
{
    # skip . and ..
    next if($file =~ /^\.$/);
    next if($file =~ /^\.\.$/);
    open(HTMLFILE, "$ARGV[0]/$file") or die "Can't find file";

    while(my $line = <HTMLFILE>) {
	if($line =~ /<title>/){
	$line =~/(?<=<title>)(.*?)(?=<\/title>)/g;
	$content = $1;

	my $outfile = "$ARGV[0]/index.html";
	open my $out, ">>$outfile" or
	    die "Can't open $outfile for writing: $!\n";
	print $out qq{  <li><a href="$file">$content</a></li>\n};

	}
    }

}


$cmd = qq{ebook-convert $ARGV[0]/index.html $ARGV[1].epub --output-profile ipad3 --no-default-epub-cover --title "$ARGV[1]" --language en};

#warn $cmd;
shell $cmd;
$cmd1 = qq{terminal-notifier -message "$ARGV[1].epub generated."};
shell $cmd1;

sub shell ($) {
    my $cmd = shift;
    #warn "command: $cmd";

    # Note: we cannot use Perl's system() here because it
    # makes the parent process completely ignore the INT
    # signal so only the child process gets it. But the
    # vim program (in the child process) does not quit
    # upon INT but just aborts our own batch vim commands,
    # leading to the tragedy that vim hangs there forever.

    my $pid = fork;
    if (!defined $pid) {
        die "failed to fork for command \"$cmd\": $!\n";
    }

    if ($pid == 0) {
        # in the child process

        open STDIN, '/dev/null' or die "Cannot read /dev/null: $!";
        open STDOUT, '/dev/null' or die "Cannott write to /dev/null: $!";
        exec $cmd or die "failed to exec command: $cmd";
    }

    # still in the parent process
    $child_pids{$pid} = 1;
    #warn "waiting on $pid for cmd $cmd...";
    waitpid $pid, 0;
    #warn "waited";
    delete $child_pids{$pid};

    if ($? != 0) {
        die qq{failed to run command "$cmd": $?\n};
    }
}
