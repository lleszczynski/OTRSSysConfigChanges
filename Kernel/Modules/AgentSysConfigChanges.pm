# --
# Copyright (C) 2020 Łukasz Leszczyński
# --
# This software comes with ABSOLUTELY NO WARRANTY.
# See https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentSysConfigChanges;

use strict;
use warnings;

use Kernel::System::EmailParser;
use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $LayoutObject           = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject            = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $SysConfigChangesObject = $Kernel::OM->Get('Kernel::System::SysConfigChanges');

	if ( $Self->{Subaction} eq 'AJAXGetChangesPreview' ) {

        my $Name = $ParamObject->GetParam( Param => 'Name' ) || '';

        my @ChangesList = $SysConfigChangesObject->ChangesList(
            Name => $Name,
        );

        my %Data;
        if (scalar @ChangesList) {
            $Data{IsChanged} = 1;
            $Data{ChangesNumber} = scalar @ChangesList;

            my $Counter = 0;
            for my $ChangeID (@ChangesList) {
                $Counter++;

                my %Change = $SysConfigChangesObject->ChangePreviewGet(
                    ID => $ChangeID,
                );

                $LayoutObject->Block(
                    Name => 'ChangeRow',
                    Data => {
                        Count => $Counter,
                        Last  => $Counter eq $Data{ChangesNumber} ? 1 : 0,
                        %Change,
                    },
                );
            }
        }

        $Data{Name} = $Name;

        my $HTML = $LayoutObject->Output(
            TemplateFile => 'SysConfigChangesPreview',
            Data         => \%Data,
        );
        
        my $JSON = $LayoutObject->JSONEncode(
            Data => {
                HTML => $HTML,
            },
        );
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    if ( $Self->{Subaction} eq 'AJAXChangeRestore' ) {

        # get needen objects
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
        my $YAMLObject      = $Kernel::OM->Get('Kernel::System::YAML');

        # get needed params
        my $Name     = $ParamObject->GetParam( Param => 'Name' ) || '';
        my $ChangeID = $ParamObject->GetParam( Param => 'ChangeID' ) || '';

        my $YAMLChangeValue = $SysConfigChangesObject->ChangeValueGet(
            Name     => $Name,
            ChangeID => $ChangeID,
        );

        my $ExclusiveLockGUID = $SysConfigObject->SettingLock(
            Name      => $Name,
            UserID    => $Self->{UserID},
        );

        my $EffectiveValue = $YAMLObject->Load(
            Data => $YAMLChangeValue,
        );

        my %Data;
        $Data{Name} = $Name;
        if (defined $ExclusiveLockGUID) {
            $SysConfigObject->SettingUpdate(
                Name              => $Name,
                EffectiveValue    => $EffectiveValue,
                ExclusiveLockGUID => $ExclusiveLockGUID,
                UserID            => $Self->{UserID},
            );
        }
        else {
            $Data{UpdateFail} = 1;
            my $HTML = $LayoutObject->Output(
                TemplateFile => 'SysConfigChangesPreview',
                Data         => \%Data,
            );
            $Data{HTML} = $HTML;
        }

        my $JSON = $LayoutObject->JSONEncode(
            Data => {
                %Data,
            },
        );
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    
    return 1;
}

1;

