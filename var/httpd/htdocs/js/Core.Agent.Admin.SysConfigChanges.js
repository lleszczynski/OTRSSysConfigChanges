// --
// Copyright (C) 2020 Łukasz Leszczyński
// Copyright (C) 2020 OTRS AG, https://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY.
// See https://www.gnu.org/licenses/gpl-3.0.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};
Core.Agent.Admin = Core.Agent.Admin || {};

Core.Agent.Admin.SysConfigChanges = (function (TargetNS) {

    TargetNS.Init = function () {
        TargetNS.InitSettingsMenu();

        Core.App.Subscribe('SystemConfiguration.SettingListUpdate', function() {
            TargetNS.InitSettingsMenu();
        });
    };

    TargetNS.InitSettingsMenu = function () {
        $('ul.SettingsList .Setting .WidgetMenu').each(function(){
            if(!$(this).find('a.ChangesAlias').length){
                $(this).append('<a href="#" class="Button Right ChangesAlias" title="' +
                    Core.Language.Translate('Changes preview') +
                    '"><i class="fa fa-history"></i> ' +
                    Core.Language.Translate('Changes') +
                    '</a>');

                $('a.ChangesAlias').off('click.OpenChangesPreview').on('click.OpenChangesPreview', function(Event) {
                    TargetNS.ChangesPreview($(this));
                    Event.stopPropagation();
                    Event.preventDefault();
                });
            }
        });
    };

    TargetNS.ChangesPreview = function($Object) {
        var Data = {
            Action    : 'AgentSysConfigChanges',
            Subaction : 'AJAXGetChangesPreview',
            Name      : $Object.closest(".WidgetSimple").find(".Header h2").text().trim(),
        };

        Core.AJAX.FunctionCall(
            Core.Config.Get('CGIHandle'),
            Data,
            function (Response) {

                var $DialogObj = $(Response.HTML);

                Core.UI.Dialog.ShowContentDialog($DialogObj, Core.Language.Translate('Changes preview'), '150px', 'Center', true);

                $("button.CloseDialog").off("click").on("click", function() {
                    Core.UI.Dialog.CloseDialog($(".Dialog"));
                });

                $("a.ChangeRestore").off("click").on("click", function() {
                    TargetNS.ChangeRestore($(this));
                });
            }, 'json'
        );
    }

    TargetNS.ChangeRestore = function($Object) {
        var Data = {
            Action    : 'AgentSysConfigChanges',
            Subaction : 'AJAXChangeRestore',
            Name      : $Object.find('input').attr('name'),
            ChangeID  : $Object.find('input').attr('value'),
        };

        Core.AJAX.FunctionCall(
            Core.Config.Get('CGIHandle'),
            Data,
            function (Response) {
                CheckSettings();
                Core.UI.Dialog.CloseDialog($(".Dialog"));
                if (Response.HTML) {
                    var $DialogObj = $(Response.HTML);

                    Core.UI.Dialog.ShowContentDialog($DialogObj, Core.Language.Translate('Changes preview'), '150px', 'Center', true);

                    $("button.CloseDialog").off("click").on("click", function() {
                        Core.UI.Dialog.CloseDialog($(".Dialog"));
                    });

                    $("a.ChangeRestore").off("click").on("click", function() {
                        TargetNS.ChangeRestore($(this));
                    });
                }
            }, 'json'
        );
    }

    // Core.Agent.Admin.SystemConfiguration.js private function copy
    function CheckSettings() {
        var URL,
            Data,
            IsLockedByAnotherUser,
            Settings = [];

        // get all unlocked settings on the page
        $("ul.SettingsList .WidgetSimple:not(.IsLockedByMe) .SettingContainer").each(function() {
            IsLockedByAnotherUser = 0;
            if ($(this).closest(".WidgetSimple").hasClass("IsLockedByAnotherUser")) {
                IsLockedByAnotherUser = 1;
            }

            Data = {};
            Data["SettingName"] = $(this).find("> input").val();
            Data["ChangeTime"] = $(this).find(".Setting").attr("data-change-time");
            Data["IsLockedByAnotherUser"] = IsLockedByAnotherUser;

            Settings.push(Data);
        });

        URL = Core.Config.Get('Baselink') +
            "Action=AdminSystemConfigurationGroup;Subaction=CheckSettings;" +
            'ChallengeToken=' + Core.Config.Get('ChallengeToken');

        // check for updates
        Core.AJAX.FunctionCall(
            URL,
            {
                Settings: Core.JSON.Stringify(Settings)
            },
            function(Response) {
                var ArrayIndex,
                    Setting,
                    $Widget;

                if (Response.Error) {
                    alert(Response.Error);
                    return;
                }

                for (ArrayIndex in Response.Data) {
                    // check if user already locked the setting
                    Setting = Response.Data[ArrayIndex];

                    $Widget = $("#Setting" + Setting.SettingData.DefaultID +":not(.IsLockedByMe)");
                    if($Widget.length > 0) {

                        // Update setting
                        Core.SystemConfiguration.SettingRender(
                            {
                                Data: Setting
                            },
                            $Widget
                        );

                        if (Setting.SettingData.IsLockedByAnotherUser) {
                            $Widget.addClass("IsLockedByAnotherUser");

                            if ($Widget.find("> .Content > .LockedByAnotherUser").length == 0) {
                                $Widget.find("> .Content").prepend('<div class="LockedByAnotherUser"></div>');
                            }
                        }
                        else {
                            $Widget.removeClass("IsLockedByAnotherUser");
                            $Widget.find("> .Content > .LockedByAnotherUser").remove();
                        }

                        if (Setting.SettingData.IsModified) {
                            $Widget.addClass("IsModified");
                        }
                        else {
                            $Widget.removeClass("IsModified");
                        }

                        if (Setting.SettingData.IsDirty) {
                            $Widget.addClass("IsDirty");
                        }
                        else {
                            $Widget.removeClass("IsDirty");
                        }
                    }
                }
            }
        );
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.SysConfigChanges || {}));
