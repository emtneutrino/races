/*

Copyright (c) 2024, Neil J. Tan
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

$(function() {
    var action;

    let replyOpen = false;
    let openPanel = "";
    let pvtTrackNames = "";
    let pubTrackNames = "";
    let pvtGrpNames = "";
    let pubGrpNames = "";
    let pvtListNames = "";
    let pubListNames = "";

    $("#mainPanel").hide();
    $("#trackPanel").hide();
    $("#aiPanel").hide();
    $("#listPanel").hide();
    $("#registerPanel").hide();
    $("#replyPanel").hide();
    $("#confirmPanel").hide();

    window.addEventListener("message", function(event) {
        let data = event.data;

        if ("init" == data.action) {
            document.getElementById("main_vehicle").innerHTML = data.allVehicles;
            $("#main_vehicle").val(data.defaultModel);
            document.getElementById("main_class").innerHTML =
                "<option value = -1>All</option>" +
                data.classes;

            document.getElementById("ai_vehicle").innerHTML = data.allVehicles;
            $("#ai_vehicle").val(data.defaultModel);

            document.getElementById("list_add_list").innerHTML = data.allVehicles;
            document.getElementById("list_class_list").innerHTML = data.classes;

            $("#register_buyin").val(data.defaultBuyin);
            $("#register_laps").val(data.defaultLaps);
            $("#register_timeout").val(data.defaultTimeout);
            $("#register_allowAI").val(data.defaultAllowAI);
            document.getElementById("register_rest_vehicle").innerHTML = data.allVehicles;
            document.getElementById("register_vclass").innerHTML =
                "<option value = -1>-1:Custom</option>" +
                data.classes;
            document.getElementById("register_rvclass").innerHTML =
                "<option value = -1>Any</option>" +
                data.classes;
            $("#register_rvclass").change()
            $("#register_recur").val(data.defaultRecur);
            $("#register_order").val(data.defaultOrder);
            $("#register_delay").val(data.defaultDelay);

            $("#register_rtype").change();
        } else if ("open" == data.action) {
            if ("main" == data.panel) {
                $("#mainPanel").show();
                openPanel = "main";
            } else if ("track" == data.panel) {
                $("#trackPanel").show();
                openPanel = "track";
            } else if ("ai" == data.panel) {
                $("#aiPanel").show();
                openPanel = "ai";
            } else if ("list" == data.panel) {
                $("#listPanel").show();
                openPanel = "list";
            } else if ("register" == data.panel) {
                $("#registerPanel").show();
                openPanel = "register";
            };
        } else if ("reply" == data.action) {
            $("#mainPanel").hide();
            $("#trackPanel").hide();
            $("#aiPanel").hide();
            $("#listPanel").hide();
            $("#registerPanel").hide();
            document.getElementById("message").innerHTML = data.message;
            $("#replyPanel").show();
            replyOpen = true;
        } else if ("confirm" == data.action) {
            $("#mainPanel").hide();
            $("#trackPanel").hide();
            $("#aiPanel").hide();
            $("#listPanel").hide();
            $("#registerPanel").hide();
            document.getElementById("confirm_message").innerHTML = data.message;
            $("#confirmPanel").show();
        } else if ("update" == data.action) {
            if ("trackNames" == data.list) {
                if ("pub" == data.access) {
                    pubTrackNames = data.trackNames;
                } else {
                    pvtTrackNames = data.trackNames;
                };
                $("#main_access").change();
                $("#track_access0").change();
                $("#register_access").change();
            } else if ("grpNames" == data.list) {
                if ("pub" == data.access) {
                    pubGrpNames = data.grpNames;
                } else {
                    pvtGrpNames = data.grpNames;
                };
                $("#ai_access0").change();
            } else if ("listNames" == data.list) {
                if ("pub" == data.access) {
                    pubListNames = data.listNames;
                } else {
                    pvtListNames = data.listNames;
                };
                $("#list_access0").change();
            } else if ("vehicleList" == data.list) {
                document.getElementById("list_delete_list").innerHTML = data.vehicleList;
            } else if ("svehicles" == data.list) {
                document.getElementById("register_start_vehicle").innerHTML = data.startVehicles;
            };
        };
    });

    /* main panel */
    $("#main_clear").click(function() {
        $.post("https://races/clear");
    });

    $("#main_access").change(function() {
        if ("pub" == $("#main_access").val()) {
            document.getElementById("main_track_name").innerHTML = pubTrackNames;
        } else {
            document.getElementById("main_track_name").innerHTML = pvtTrackNames;
        };
    });

    $("#main_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            access: $("#main_access").val(),
            name: $("#main_track_name").val()
        }));
    });

    $("#main_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            access: $("#main_access").val(),
            name: $("#main_track_name").val()
        }));
    });

    $("#main_list").click(function() {
        $.post("https://races/list", JSON.stringify({
            access: $("#main_access").val()
        }));
    });

    $("#main_leave").click(function() {
        $.post("https://races/leave");
    });

    $("#main_rivals").click(function() {
        $.post("https://races/rivals");
    });

    $("#main_respawn").click(function() {
        $.post("https://races/respawn");
    });

    $("#main_results").click(function() {
        $.post("https://races/results");
    });

    $("#main_spawn").click(function() {
        $.post("https://races/spawn", JSON.stringify({
            vehicle: $("#main_vehicle").val()
        }));
    });

    $("#main_lvehicles").click(function() {
        $.post("https://races/lvehicles", JSON.stringify({
            vclass: $("#main_class").val()
        }));
    });

    $("#main_speedo").click(function() {
        $.post("https://races/speedo", JSON.stringify({
            unit: ""
        }));
    });

    $("#main_change").click(function() {
        $.post("https://races/speedo", JSON.stringify({
            unit: $("#main_unit").val()
        }));
    });

    $("#main_funds").click(function() {
        $.post("https://races/funds");
    });

    $("#main_track").click(function() {
        $("#mainPanel").hide();
        $("#trackPanel").show();
        openPanel = "track";
    });

    $("#main_ai").click(function() {
        $("#mainPanel").hide();
        $("#aiPanel").show();
        openPanel = "ai";
    });

    $("#main_vlist").click(function() {
        $("#mainPanel").hide();
        $("#listPanel").show();
        openPanel = "list";
    });

    $("#main_register").click(function() {
        $("#mainPanel").hide();
        $("#registerPanel").show();
        openPanel = "register";
    });

    $("#main_close").click(function() {
        $("#mainPanel").hide();
        $.post("https://races/close");
    });

    /* track panel */
    $("#track_edit").click(function() {
        $.post("https://races/edit");
    });

    $("#track_clear").click(function() {
        $.post("https://races/clear");
    });

    $("#track_reverse").click(function() {
        $.post("https://races/reverse");
    });

    $("#track_access0").change(function() {
        if ("pub" == $("#track_access0").val()) {
            document.getElementById("track_track_name").innerHTML = pubTrackNames;
        } else {
            document.getElementById("track_track_name").innerHTML = pvtTrackNames;
        };
    });

    $("#track_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            access: $("#track_access0").val(),
            name: $("#track_track_name").val()
        }));
    });

    function overwriteTrack() {
        $.post("https://races/overwrite", JSON.stringify({
            access: $("#track_access0").val(),
            name: $("#track_track_name").val()
        }));
    }

    $("#track_overwrite").click(function() {
        $("#trackPanel").hide();
        action = overwriteTrack
        if ("pub" == $("#track_access0").val()) {
            document.getElementById("confirm_message").innerHTML = "Confirm overwrite public track '" + $("#track_track_name").val() + "'?";
        } else {
            document.getElementById("confirm_message").innerHTML = "Confirm overwrite private track '" + $("#track_track_name").val() + "'?";
        }
        $("#confirmPanel").show();
    });

    function deleteTrack() {
        $.post("https://races/delete", JSON.stringify({
            access: $("#track_access0").val(),
            name: $("#track_track_name").val()
        }));
    }

    $("#track_delete").click(function() {
        $("#trackPanel").hide();
        action = deleteTrack
        if ("pub" == $("#track_access0").val()) {
            document.getElementById("confirm_message").innerHTML = "Confirm delete public track '" + $("#track_track_name").val() + "'?";
        } else {
            document.getElementById("confirm_message").innerHTML = "Confirm delete private track '" + $("#track_track_name").val() + "'?";
        }
        $("#confirmPanel").show();
    });

    $("#track_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            access: $("#track_access0").val(),
            name: $("#track_track_name").val()
        }));
    });

    $("#track_list").click(function() {
        $.post("https://races/list", JSON.stringify({
            access: $("#track_access0").val()
        }));
    });

    $("#track_save").click(function() {
        $.post("https://races/save", JSON.stringify({
            access: $("#track_access1").val(),
            name: $("#track_unsaved").val()
        }));
    });

    $("#track_main").click(function() {
        $("#trackPanel").hide();
        $("#mainPanel").show();
        openPanel = "main";
    });

    $("#track_ai").click(function() {
        $("#trackPanel").hide();
        $("#aiPanel").show();
        openPanel = "ai";
    });

    $("#track_vlist").click(function() {
        $("#trackPanel").hide();
        $("#listPanel").show();
        openPanel = "list";
    });

    $("#track_register").click(function() {
        $("#trackPanel").hide();
        $("#registerPanel").show();
        openPanel = "register";
    });

    $("#track_close").click(function() {
        $("#trackPanel").hide();
        $.post("https://races/close");
    });

    /* AI panel */
    $("#ai_spawn").click(function() {
        $.post("https://races/spawn_ai", JSON.stringify({
            name: $("#ai_ai_name").val(),
            vehicle: $("#ai_vehicle").val()
        }));
    });

    $("#ai_delete").click(function() {
        $.post("https://races/delete_ai", JSON.stringify({
            name: $("#ai_ai_name").val()
        }));
    });

    $("#ai_list").click(function() {
        $.post("https://races/list_ai");
    });

    $("#ai_delete_all").click(function() {
        $.post("https://races/delete_all_ai");
    });

    $("#ai_access0").change(function() {
        if ("pub" == $("#ai_access0").val()) {
            document.getElementById("ai_group_name").innerHTML = pubGrpNames;
        } else {
            document.getElementById("ai_group_name").innerHTML = pvtGrpNames;
        };
    });

    $("#ai_load_grp").click(function() {
        $.post("https://races/load_grp", JSON.stringify({
            access: $("#ai_access0").val(),
            name: $("#ai_group_name").val()
        }));
    });

    function overwriteGroup() {
        $.post("https://races/overwrite_grp", JSON.stringify({
            access: $("#ai_access0").val(),
            name: $("#ai_group_name").val()
        }));
    }

    $("#ai_overwrite_grp").click(function() {
        $("#aiPanel").hide();
        action = overwriteGroup
        if ("pub" == $("#ai_access0").val()) {
            document.getElementById("confirm_message").innerHTML = "Confirm overwrite public AI group '" + $("#ai_group_name").val() + "'?";
        } else {
            document.getElementById("confirm_message").innerHTML = "Confirm overwrite private AI group '" + $("#ai_group_name").val() + "'?";
        }
        $("#confirmPanel").show();
    });

    function deleteGroup() {
        $.post("https://races/delete_grp", JSON.stringify({
            access: $("#ai_access0").val(),
            name: $("#ai_group_name").val()
        }));
    }

    $("#ai_delete_grp").click(function() {
        $("#aiPanel").hide();
        action = deleteGroup
        if ("pub" == $("#ai_access0").val()) {
            document.getElementById("confirm_message").innerHTML = "Confirm delete publlic AI group '" + $("#ai_group_name").val() + "'?";
        } else {
            document.getElementById("confirm_message").innerHTML = "Confirm delete private AI group '" + $("#ai_group_name").val() + "'?";
        }
            $("#confirmPanel").show();
    });

    $("#ai_list_grps").click(function() {
        $.post("https://races/list_grps", JSON.stringify({
            access: $("#ai_access0").val()
        }));
    });

    $("#ai_save_grp").click(function() {
        $.post("https://races/save_grp", JSON.stringify({
            access: $("#ai_access1").val(),
            name: $("#ai_unsaved").val()
        }));
    });

    $("#ai_main").click(function() {
        $("#aiPanel").hide();
        $("#mainPanel").show();
        openPanel = "main";
    });

    $("#ai_track").click(function() {
        $("#aiPanel").hide();
        $("#trackPanel").show();
        openPanel = "track";
    });

    $("#ai_vlist").click(function() {
        $("#aiPanel").hide();
        $("#listPanel").show();
        openPanel = "list";
    });

    $("#ai_register").click(function() {
        $("#aiPanel").hide();
        $("#registerPanel").show();
        openPanel = "register";
    });

    $("#ai_close").click(function() {
        $("#aiPanel").hide();
        $.post("https://races/close");
    });

    /* vehicle list panel */
    $("#list_add_veh").click(function() {
        $.post("https://races/add_veh", JSON.stringify({
            vehicle: $("#list_add_list").val()
        }));
    });

    $("#list_delete_veh").click(function() {
        $.post("https://races/delete_veh", JSON.stringify({
            vehicle: $("#list_delete_list").val()
        }));
    });

    $("#list_add_class").click(function() {
        $.post("https://races/add_class", JSON.stringify({
            class: $("#list_class_list").val()
        }));
    });

    $("#list_delete_class").click(function() {
        $.post("https://races/delete_class", JSON.stringify({
            class: $("#list_class_list").val()
        }));
    });

    $("#list_add_all_veh").click(function() {
        $.post("https://races/add_all_veh");
    });

    $("#list_delete_all_veh").click(function() {
        $.post("https://races/delete_all_veh");
    });

    $("#list_list_veh").click(function() {
        $.post("https://races/list_veh");
    });

    $("#list_access0").change(function() {
        if ("pub" == $("#list_access0").val()) {
            document.getElementById("list_vl_name").innerHTML = pubListNames;
        } else {
            document.getElementById("list_vl_name").innerHTML = pvtListNames;
        };
    });

    $("#list_load").click(function() {
        $.post("https://races/load_list", JSON.stringify({
            access: $("#list_access0").val(),
            name: $("#list_vl_name").val()
        }));
    });

    function overwriteList() {
        $.post("https://races/overwrite_list", JSON.stringify({
            access: $("#list_access0").val(),
            name: $("#list_vl_name").val()
        }));
    }

    $("#list_overwrite").click(function() {
        $("#listPanel").hide();
        action = overwriteList
        if ("pub" == $("#list_access0").val()) {
            document.getElementById("confirm_message").innerHTML = "Confirm overwrite public vehicle list '" + $("#list_vl_name").val() + "'?";
        } else {
            document.getElementById("confirm_message").innerHTML = "Confirm overwrite private vehicle list '" + $("#list_vl_name").val() + "'?";
        }
        $("#confirmPanel").show();
    });

    function deleteList() {
        $.post("https://races/delete_list", JSON.stringify({
            access: $("#list_access0").val(),
            name: $("#list_vl_name").val()
        }));
    }

    $("#list_delete").click(function() {
        $("#listPanel").hide();
        action = deleteList
        if ("pub" == $("#list_access0").val()) {
            document.getElementById("confirm_message").innerHTML = "Confirm delete public vehicle list '" + $("#list_vl_name").val() + "'?";
        } else {
            document.getElementById("confirm_message").innerHTML = "Confirm delete private vehicle list '" + $("#list_vl_name").val() + "'?";
        }
        $("#confirmPanel").show();
    });

    $("#list_list").click(function() {
        $.post("https://races/list_lists", JSON.stringify({
            access: $("#list_access0").val()
        }));
    });

    $("#list_save").click(function() {
        $.post("https://races/save_list", JSON.stringify({
            access: $("#list_access1").val(),
            name: $("#list_unsaved").val()
        }));
    });

    $("#list_main").click(function() {
        $("#listPanel").hide();
        $("#mainPanel").show();
        openPanel = "main";
    });

    $("#list_track").click(function() {
        $("#listPanel").hide();
        $("#trackPanel").show();
        openPanel = "track";
    });

    $("#list_ai").click(function() {
        $("#listPanel").hide();
        $("#aiPanel").show();
        openPanel = "ai";
    });

    $("#list_register").click(function() {
        $("#listPanel").hide();
        $("#registerPanel").show();
        openPanel = "register";
    });

    $("#list_close").click(function() {
        $("#listPanel").hide();
        $.post("https://races/close");
    });

    /* register panel */
    $("#register_access").change(function() {
        if ("pub" == $("#register_access").val()) {
            document.getElementById("register_track_name").innerHTML = pubTrackNames;
        } else {
            document.getElementById("register_track_name").innerHTML = pvtTrackNames;
        };
    });

    $("#register_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            access: $("#register_access").val(),
            name: $("#register_track_name").val()
        }));
    });

    $("#register_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            access: $("#register_access").val(),
            name: $("#register_track_name").val()
        }));
    });

    $("#register_list").click(function() {
        $.post("https://races/list", JSON.stringify({
            access: $("#register_access").val()
        }));
    });

    $("#register_rtype").change(function() {
        if ("norm" == $("#register_rtype").val()) {
            $("#register_rest").hide();
            $("#register_class").hide();
            $("#register_rclass").hide();
            $("#register_sveh").hide();
            $("#register_recurring").hide();
            $("#register_ordered").hide();
        } else if ("rest" == $("#register_rtype").val()) {
            $("#register_rest").show();
            $("#register_class").hide();
            $("#register_rclass").hide();
            $("#register_sveh").hide();
            $("#register_recurring").hide();
            $("#register_ordered").hide();
        } else if ("class" == $("#register_rtype").val()) {
            $("#register_rest").hide();
            $("#register_class").show();
            $("#register_rclass").hide();
            $("#register_sveh").hide();
            $("#register_recurring").hide();
            $("#register_ordered").hide();
        } else if ("rand" == $("#register_rtype").val()) {
            $("#register_rest").hide();
            $("#register_class").hide();
            $("#register_rclass").show();
            $("#register_sveh").show();
            $("#register_recurring").show();
            $("#register_ordered").show();
        };
    });

    $("#register_rvclass").change(function() {
        $.post("https://races/vclass", JSON.stringify({
            vclass: $("#register_rvclass").val()
        }));
    });

    $("#register_register").click(function() {
        let vclass = "";
        if ("class" == $("#register_rtype").val()) {
            vclass = $("#register_vclass").val();
        } else if ("rand" == $("#register_rtype").val()) {
            vclass = $("#register_rvclass").val();
        };
        $.post("https://races/register", JSON.stringify({
            buyin: $("#register_buyin").val(),
            laps: $("#register_laps").val(),
            timeout: $("#register_timeout").val(),
            allowAI: $("#register_allowAI").val(),
            rtype: $("#register_rtype").val(),
            restrict: $("#register_rest_vehicle").val(),
            vclass: vclass,
            svehicle: $("#register_start_vehicle").val(),
            recur: $("#register_recur").val(),
            order: $("#register_order").val()
        }));
    });

    $("#register_unregister").click(function() {
        $.post("https://races/unregister");
    });

    $("#register_start").click(function() {
        $.post("https://races/start", JSON.stringify({
            delay: $("#register_delay").val()
        }));
    });

    $("#register_main").click(function() {
        $("#registerPanel").hide();
        $("#mainPanel").show();
        openPanel = "main";
    });

    $("#register_track").click(function() {
        $("#registerPanel").hide();
        $("#trackPanel").show();
        openPanel = "track";
    });

    $("#register_ai").click(function() {
        $("#registerPanel").hide();
        $("#aiPanel").show();
        openPanel = "ai";
    });

    $("#register_vlist").click(function() {
        $("#registerPanel").hide();
        $("#listPanel").show();
        openPanel = "list";
    });

    $("#register_close").click(function() {
        $("#registerPanel").hide();
        $.post("https://races/close");
    });

    /* reply panel */
    $("#reply_close").click(function() {
        $("#replyPanel").hide();
        replyOpen = false;
        if ("main" == openPanel) {
            $("#mainPanel").show();
        } else if("track" == openPanel) {
            $("#trackPanel").show();
        } else if("ai" == openPanel) {
            $("#aiPanel").show();
        } else if("list" == openPanel) {
            $("#listPanel").show();
        } else if("register" == openPanel) {
            $("#registerPanel").show();
        };
    });

    /* confirm panel */
    $("#confirm_yes").click(function() {
        $("#confirmPanel").hide();
        action()
    });

    $("#confirm_no").click(function() {
        $("#confirmPanel").hide();
        if ("main" == openPanel) {
            $("#mainPanel").show();
        } else if("track" == openPanel) {
            $("#trackPanel").show();
        } else if("ai" == openPanel) {
            $("#aiPanel").show();
        } else if("list" == openPanel) {
            $("#listPanel").show();
        } else if("register" == openPanel) {
            $("#registerPanel").show();
        };
    });

    document.onkeyup = function(data) {
        if (data.key == "Escape") {
            if (true == replyOpen) {
                $("#reply_close").click();
            } else {
                $("#mainPanel").hide();
                $("#trackPanel").hide();
                $("#aiPanel").hide();
                $("#listPanel").hide();
                $("#registerPanel").hide();
                $.post("https://races/close");
            };
        };
    };
});
