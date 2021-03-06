# --
# Copyright (C) 2020 Łukasz Leszczyński
# --
# This software comes with ABSOLUTELY NO WARRANTY.
# See https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::SysConfigChanges;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::User',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub ChangesList {
    my ( $Self, %Param ) = @_;

    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # create sql
    my $SQL = 'SELECT id ' .
        'FROM sysconfig_modified_version ' .
        'WHERE name = ?' .
        'ORDER BY create_time';


    return if !$DBObject->Prepare(
        SQL => $SQL,
        Bind => [\$Param{Name}],
    );

    # fetch the result
    my @Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @Data, $Row[0];
    }

    return @Data;
}

sub ChangePreviewGet {
    my ( $Self, %Param ) = @_;

    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # create sql
    my $SQL = 'SELECT id, sysconfig_default_version_id, name, is_valid, effective_value, reset_to_default, create_time, create_by ' .
        'FROM sysconfig_modified_version ' .
        'WHERE id = ?' .
        'ORDER BY create_time';


    return if !$DBObject->Prepare(
        SQL => $SQL,
        Bind => [\$Param{ID}],
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}               = $Row[0];
        $Data{DefaultVersionID} = $Row[1];
        $Data{Name}             = $Row[2];
        $Data{IsValid}          = $Row[3];
        $Data{EffectiveValue}   = $Row[4];
        $Data{ResetToDefault}   = $Row[5];
        $Data{CreateTime}       = $Row[6];
        $Data{CreateBy}         = $UserObject->UserLookup(UserID => $Row[7], Silent => 1);
    }

    return %Data;
}

sub ChangeValueGet {
    my ( $Self, %Param ) = @_;

    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # create sql
    my $SQL = 'SELECT effective_value ' .
        'FROM sysconfig_modified_version ' .
        'WHERE id = ?';


    return if !$DBObject->Prepare(
        SQL => $SQL,
        Bind => [\$Param{ChangeID}],
    );

    # fetch the result
    my $Result;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Result   = $Row[0];
    }

    return $Result;
}

1;
