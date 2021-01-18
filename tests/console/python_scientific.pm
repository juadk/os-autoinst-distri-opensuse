# SUSE's openQA tests
#
# Copyright © 2021 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Scientific python packages
# * Test numpy
# * Test scipy
# Maintainer: Felix Niederwanger <felix.niederwanger@suse.de>

use base 'consoletest';
use strict;
use warnings;
use testapi;
use utils;
use version_utils qw(is_sle);
use registration qw(cleanup_registration register_product add_suseconnect_product get_addon_fullname remove_suseconnect_product);

sub run_python_script {
    my $script  = shift;
    my $logfile = "output.txt";
    record_info($script, "Running python script: $script");
    assert_script_run("curl " . data_url("python/$script") . " -o '$script'");
    assert_script_run("chmod a+rx '$script'");
    assert_script_run("./$script 2>&1 | tee $logfile");
    if (script_run("grep 'Softfail' $logfile") == 0) {
        my $failmsg = script_output("grep 'Softfail' '$logfile'");
        record_soft_failure("$failmsg");
    }
}

sub run {
    my $self = shift;
    $self->select_serial_terminal;
    if (is_sle) {
        cleanup_registration();
        register_product();
        add_suseconnect_product(get_addon_fullname('phub'));
    }
    my $scipy = is_sle('<15-sp1') ? '' : 'python3-scipy';
    zypper_call "in python3 python3-numpy $scipy";
    # Run python scripts
    run_python_script('python3-numpy-test.py');
    run_python_script('python3-scipy-test.py') unless is_sle('<15-sp1');
}

sub cleanup() {
    if (is_sle) {
        remove_suseconnect_product(get_addon_fullname('phub'));
    }
}

sub post_fail_hook {
    my $self = shift;
    cleanup();
    $self->SUPER::post_fail_hook;
}

sub post_run_hook {
    my $self = shift;
    cleanup();
    $self->SUPER::post_run_hook;
}

1;