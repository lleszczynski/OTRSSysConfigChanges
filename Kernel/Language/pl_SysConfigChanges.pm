# --
# Copyright (C) 2020 Łukasz Leszczyński
# --
# This software comes with ABSOLUTELY NO WARRANTY.
# See https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Language::pl_SysConfigChanges;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;
    
    $Self->{Translation}->{'Changes preview'} = 'Przegląd zmian';
    $Self->{Translation}->{'Changes'} = 'Zmiany';
    $Self->{Translation}->{'This setting is currently locked by another user.'} = 'To ustawienie jest obecnie edytowane przez innego użytkownika.';
    $Self->{Translation}->{'This setting has not been changed.'} = 'To ustawienie nie było zmieniane.';
    $Self->{Translation}->{'Restore'} = 'Odtwórz';

    return 1;
}

1;
