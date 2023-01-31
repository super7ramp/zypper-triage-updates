#!/usr/bin/gawk -E

#
# SPDX-FileCopyrightText: 2023 Antoine Belvire
# SPDX-License-Identifier: GPL-3.0-or-later
#

#
# Analyses output of `zypper lu` to determine the kind of each update:
#
# - Upstream update: Upstream has bumped version
# - Downstream update: No upstream version change, only source change by downstream
# - Downstream rebuild: No source change, only build counter bump
#

#
# Initialisation.
#
BEGIN {
    # Field separator is | with any number of blanks around (so that fields are trimmed)
    FS="[ ]*\\|[ ]*"

    # Statistics
    upstream_update_count = 0
    downstream_update_count = 0
    rebuild_count = 0
}

#
# Print update kind and update statistics.
#
is_version($4) && is_version($5) {

    app_name = $3
    old_version = $4
    new_version = $5

    update_kind = determine_update_kind(old_version, new_version)

    if (update_kind == "Upstream update") {
        upstream_update_count++
    } else if (update_kind == "Downstream update") {
        downstream_update_count++
    } else {
        rebuild_count++
    }

    print update_kind " for " app_name " from " old_version " to " new_version
}

#
# After all lines consumed, print statistics.
#
END {

    total = upstream_update_count + downstream_update_count + rebuild_count
    if (total > 0) {
        print ""
        print "Number of upstream updates: " upstream_update_count " (" percentage(upstream_update_count, total) "%)"
        print "Number of downstream updates: " downstream_update_count  " (" percentage(downstream_update_count, total) "%)"
        print "Number of rebuilds: " rebuild_count " (" percentage(rebuild_count, total) "%)"
    }
    print "Total: " total
}

# Returns 1 if given string matches the expected version format, 0 otherwise.
# Expected version format is "{upstream_version}-{release_version}.{rebuild_counter}".
function is_version(str) {
    return str ~ /^[^-]+-[^\.-]+\.[^\.-]+$/
}

# Returns a string describing the kind of update given two versions.
function determine_update_kind(old_version, new_version) {

    new_version_suffix = substr(new_version, diff(old_version, new_version))

    if (index(new_version_suffix, "-") > 0) {
        # If "-" is in the diff, it means that preceding upstream versions are different
        return "Upstream update"
    }
    
    if (index(new_version_suffix, ".") > 0) {
        # If "." is in the diff, it means that preceding release versions are different
        return "Downstream update"
    }

    # Only rebuild counter part differs between old and new versions
    return "Downstream rebuild"
}

# Returns the index of the first different character between two strings.
# If one of the string starts with the other (containing it), 0 is returned.
function diff(str1, str2) {
    split(str1, str1_chars, "")
    split(str2, str2_chars, "")
    min_length = min(length(str1), length(str2))
    diff_start_index = 0
    for (i = 1; i <= min_length; i++) {
        if (str1_chars[i] != str2_chars[i]) {
           diff_start_index = i
           break
        }
    }
    return diff_start_index
}

# Return min value between two integers.
function min(int1, int2) {
   return int1 < int2 ? int1 : int2
}

# Return 
function percentage(part, total) {
   return part * 100 / total
}
