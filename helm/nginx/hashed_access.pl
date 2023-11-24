package hashed_access;

use Digest::MD5 qw(md5_hex);
use strict;
use nginx;
use warnings;

sub handler {
    my $r = shift;
    warn "hashed_access: handler started";

    my $root_dir = '/usr/share/tg-data';
    warn "hashed_access: root directory is $root_dir";

    # Extract the folder hash, subfolder path, and file name hash from the request
    my ($folder_hash, $subfolder_path, $file_name_hash) = $r->uri =~ m{^/([a-f0-9]{32})/(.+?)/([a-f0-9]{32})/?$};
    warn "hashed_access: extracted folder hash $folder_hash, subfolder path $subfolder_path, and file name hash $file_name_hash";

    opendir(my $dh, $root_dir) || die "Can't open $root_dir: $!";
    warn "hashed_access: opened directory $root_dir";

    while (my $folder = readdir($dh)) {
        next if $folder =~ /^\./;
        if ($folder =~ /^[0-9]+:[A-Za-z0-9_-]+$/) {
            my $hash = md5_hex($folder);
            warn "hashed_access: calculated hash $hash for folder $folder";

            if ($hash eq $folder_hash) {
                # Construct full path to the subfolder
                my $full_subfolder_path = "$root_dir/$folder/$subfolder_path";
                unless (-d $full_subfolder_path) {
                    warn "hashed_access: subfolder $full_subfolder_path does not exist";
                    next;
                }

                # Search for the file with the matching hash in the subfolder
                opendir(my $file_dh, $full_subfolder_path) || die "Can't open $full_subfolder_path: $!";
                warn "hashed_access: searching in subfolder $full_subfolder_path";

                while (my $file = readdir($file_dh)) {
                    next if $file =~ /^\./;
                    # Calculate the hash using the root directory and the file name
                    my $file_hash = md5_hex("$folder|$file");
                    warn "hashed_access: calculated hash $file_hash for file $file";

                    if ($file_hash eq $file_name_hash) {
                        # Construct and set the new URI
                        my $new_uri = "/$folder/$subfolder_path/$file";
                        warn "hashed_access: file hash matched, redirecting to $new_uri";
                        $r->internal_redirect($new_uri);
                        closedir($file_dh);
                        closedir($dh);
                        return OK;
                    }
                }
                closedir($file_dh);
            }
        }
    }

    warn "hashed_access: no matching folder or file found for hashes $folder_hash, $file_name_hash";
    closedir($dh);
    return 444;
}

1;
