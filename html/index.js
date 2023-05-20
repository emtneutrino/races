/*

Copyright (c) 2023, Neil J. Tan
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

    window.addEventListener("message", function(event) {
        let data = event.data;
        if ("main" == data.panel) {
            document.getElementById("main_vehicle").innerHTML = data.allVehicles;
            $("#main_vehicle").val(data.defaultModel);
            $("#mainPanel").show();
            openPanel = "main";
        } else if ("track" == data.panel) {
            $("#trackPanel").show();
            openPanel = "track";
        } else if ("ai" == data.panel) {
            document.getElementById("ai_vehicle").innerHTML = data.allVehicles;
            $("#ai_vehicle").val(data.defaultModel);
            $("#aiPanel").show();
            openPanel = "ai";
        } else if ("list" == data.panel) {
            document.getElementById("list_add_list").innerHTML = data.allVehicles;
            $("#listPanel").show();
            openPanel = "list";
        } else if ("register" == data.panel) {
            $("#register_buyin").val(data.defaultBuyin);
            $("#register_laps").val(data.defaultLaps);
            $("#register_timeout").val(data.defaultTimeout);
            $("#register_allowAI").val(data.defaultAllowAI);
            $("#register_delay").val(data.defaultDelay);
            $("#register_rtype").change();
            document.getElementById("register_rest_vehicle").innerHTML = data.allVehicles;
            document.getElementById("register_start_vehicle").innerHTML =
                "<option value = \"\"></option>" +
                data.allVehicles;
            $("#registerPanel").show();
            openPanel = "register";
        } else if ("reply" == data.panel) {
            $("#mainPanel").hide();
            $("#trackPanel").hide();
            $("#aiPanel").hide();
            $("#listPanel").hide();
            $("#registerPanel").hide();
            document.getElementById("message").innerHTML = data.message;
            $("#replyPanel").show();
            replyOpen = true;
        } else if ("trackNames" == data.update) {
            if ("pvt" == data.access) {
                pvtTrackNames = data.trackNames;
            } else if ("pub" == data.access) {
                pubTrackNames = data.trackNames;
            };
            $("#main_access").change()
            $("#track_access0").change()
            $("#register_access").change()
        } else if ("grpNames" == data.update) {
            if ("pvt" == data.access) {
                pvtGrpNames = data.grpNames;
            } else if ("pub" == data.access) {
                pubGrpNames = data.grpNames;
            };
            $("#ai_access0").change()
        } else if ("listNames" == data.update) {
            if ("pvt" == data.access) {
                pvtListNames = data.listNames;
            } else if ("pub" == data.access) {
                pubListNames = data.listNames;
            };
            $("#list_access0").change()
        } else if ("vehicleList" == data.update) {
            document.getElementById("list_delete_list").innerHTML = data.vehicleList;
        };
    });

    /* main panel */
    $("#main_clear").click(function() {
        $.post("https://races/clear");
    });

    $("#main_access").change(function() {
        if ("pvt" == $("#main_access").val()) {
            document.getElementById("main_track_name").innerHTML = pvtTrackNames;
        } else {
            document.getElementById("main_track_name").innerHTML = pubTrackNames;
        }
    });

    $("#main_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            access: $("#main_access").val(),
            trackName: $("#main_track_name").val()
        }));
    });

    $("#main_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            access: $("#main_access").val(),
            trackName: $("#main_track_name").val()
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
        $.post("https://races/show", JSON.stringify({
            panel: "track"
        }));
    });

    $("#main_ai").click(function() {
        $("#mainPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "ai"
        }));
    });

    $("#main_vlist").click(function() {
        $("#mainPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "list"
        }));
    });

    $("#main_register").click(function() {
        $("#mainPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "register"
        }));
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
        if ("pvt" == $("#track_access0").val()) {
            document.getElementById("track_track_name").innerHTML = pvtTrackNames;
        } else {
            document.getElementById("track_track_name").innerHTML = pubTrackNames;
        }
    });

    $("#track_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            access: $("#track_access0").val(),
            trackName: $("#track_track_name").val()
        }));
    });

    $("#track_overwrite").click(function() {
        $.post("https://races/overwrite", JSON.stringify({
            access: $("#track_access0").val(),
            trackName: $("#track_track_name").val()
        }));
    });

    $("#track_delete").click(function() {
        $.post("https://races/delete", JSON.stringify({
            access: $("#track_access0").val(),
            trackName: $("#track_track_name").val()
        }));
    });

    $("#track_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            access: $("#track_access0").val(),
            trackName: $("#track_track_name").val()
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
            trackName: $("#track_unsaved").val()
        }));
    });

    $("#track_main").click(function() {
        $("#trackPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "main"
        }));
    });

    $("#track_ai").click(function() {
        $("#trackPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "ai"
        }));
    });

    $("#track_vlist").click(function() {
        $("#trackPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "list"
        }));
    });

    $("#track_register").click(function() {
        $("#trackPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "register"
        }));
    });

    $("#track_close").click(function() {
        $("#trackPanel").hide();
        $.post("https://races/close");
    });

    /* AI panel */
    $("#ai_add").click(function() {
        $.post("https://races/add_ai", JSON.stringify({
            aiName: $("#ai_ai_name").val()
        }));
    });

    $("#ai_delete").click(function() {
        $.post("https://races/delete_ai", JSON.stringify({
            aiName: $("#ai_ai_name").val()
        }));
    });

    $("#ai_spawn").click(function() {
        $.post("https://races/spawn_ai", JSON.stringify({
            aiName: $("#ai_ai_name").val(),
            vehicle: $("#ai_vehicle").val()
        }));
    });

    $("#ai_list").click(function() {
        $.post("https://races/list_ai");
    });

    $("#ai_delete_all").click(function() {
        $.post("https://races/delete_all_ai");
    });

    $("#ai_access0").change(function() {
        if ("pvt" == $("#ai_access0").val()) {
            document.getElementById("ai_group_name").innerHTML = pvtGrpNames;
        } else {
            document.getElementById("ai_group_name").innerHTML = pubGrpNames;
        }
    });

    $("#ai_load_grp").click(function() {
        $.post("https://races/load_grp", JSON.stringify({
            access: $("#ai_access0").val(),
            name: $("#ai_group_name").val()
        }));
    });

    $("#ai_overwrite_grp").click(function() {
        $.post("https://races/overwrite_grp", JSON.stringify({
            access: $("#ai_access0").val(),
            name: $("#ai_group_name").val()
        }));
    });

    $("#ai_delete_grp").click(function() {
        $.post("https://races/delete_grp", JSON.stringify({
            access: $("#ai_access0").val(),
            name: $("#ai_group_name").val()
        }));
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
        $.post("https://races/show", JSON.stringify({
            panel: "main"
        }));
    });

    $("#ai_track").click(function() {
        $("#aiPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "track"
        }));
    });

    $("#ai_vlist").click(function() {
        $("#aiPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "list"
        }));
    });

    $("#ai_register").click(function() {
        $("#aiPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "register"
        }));
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
        if ("pvt" == $("#list_access0").val()) {
            document.getElementById("list_vl_name").innerHTML = pvtListNames;
        } else {
            document.getElementById("list_vl_name").innerHTML = pubListNames;
        }
    });

    $("#list_load").click(function() {
        $.post("https://races/load_list", JSON.stringify({
            access: $("#list_access0").val(),
            name: $("#list_vl_name").val()
        }));
    });

    $("#list_overwrite").click(function() {
        $.post("https://races/overwrite_list", JSON.stringify({
            access: $("#list_access0").val(),
            name: $("#list_vl_name").val()
        }));
    });

    $("#list_delete").click(function() {
        $.post("https://races/delete_list", JSON.stringify({
            access: $("#list_access0").val(),
            name: $("#list_vl_name").val()
        }));
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
        $.post("https://races/show", JSON.stringify({
            panel: "main"
        }));
    });

    $("#list_track").click(function() {
        $("#listPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "track"
        }));
    });

    $("#list_ai").click(function() {
        $("#listPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "ai"
        }));
    });

    $("#list_register").click(function() {
        $("#listPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "register"
        }));
    });

    $("#list_close").click(function() {
        $("#listPanel").hide();
        $.post("https://races/close");
    });

    /* register panel */
    $("#register_access").change(function() {
        if ("pvt" == $("#register_access").val()) {
            document.getElementById("register_track_name").innerHTML = pvtTrackNames;
        } else {
            document.getElementById("register_track_name").innerHTML = pubTrackNames;
        }
    });

    $("#register_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            access: $("#register_access").val(),
            trackName: $("#register_track_name").val()
        }));
    });

    $("#register_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            access: $("#register_access").val(),
            trackName: $("#register_track_name").val()
        }));
    });

    $("#register_list").click(function() {
        $.post("https://races/list", JSON.stringify({
            access: $("#register_access").val()
        }));
    });

    $("#register_rtype").change(function() {
        let html =
            "<option value = 0>0:Compacts</option>" +
            "<option value = 1>1:Sedans</option>" +
            "<option value = 2>2:SUVs</option>" +
            "<option value = 3>3:Coupes</option>" +
            "<option value = 4>4:Muscle</option>" +
            "<option value = 5>5:Sports Classics</option>" +
            "<option value = 6>6:Sports</option>" +
            "<option value = 7>7:Super</option>" +
            "<option value = 8>8:Motorcycles</option>" +
            "<option value = 9>9:Off-road</option>" +
            "<option value = 10>10:Industrial</option>" +
            "<option value = 11>11:Utility</option>" +
            "<option value = 12>12:Vans</option>" +
            "<option value = 13>13:Cycles</option>" +
            "<option value = 14>14:Boats</option>" +
            "<option value = 15>15:Helicopters</option>" +
            "<option value = 16>16:Planes</option>" +
            "<option value = 17>17:Service</option>" +
            "<option value = 18>18:Emergency</option>" +
            "<option value = 19>19:Military</option>" +
            "<option value = 20>20:Commercial</option>" +
            "<option value = 21>21:Trains</option>";
        if ("norm" == $("#register_rtype").val()) {
            $("#register_rest").hide();
            $("#register_class").hide();
            $("#register_sveh").hide();
        } else if ("rest" == $("#register_rtype").val()) {
            $("#register_rest").show();
            $("#register_class").hide();
            $("#register_sveh").hide();
        } else if ("class" == $("#register_rtype").val()) {
            $("#register_rest").hide();
            document.getElementById("register_vclass").innerHTML =
                "<option value = -1>-1:Custom</option>" +
                html;
            $("#register_class").show();
            $("#register_sveh").hide();
        } else if ("rand" == $("#register_rtype").val()) {
            $("#register_rest").hide();
            document.getElementById("register_vclass").innerHTML =
                "<option value = -2>Any</option>" +
                html;
            $("#register_class").show();
            $("#register_sveh").show();
        };
    });

    $("#register_register").click(function() {
        $.post("https://races/register", JSON.stringify({
            buyin: $("#register_buyin").val(),
            laps: $("#register_laps").val(),
            timeout: $("#register_timeout").val(),
            allowAI: $("#register_allowAI").val(),
            rtype: $("#register_rtype").val(),
            restrict: $("#register_rest_vehicle").val(),
            vclass: $("#register_vclass").val(),
            svehicle: $("#register_start_vehicle").val()
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
        $.post("https://races/show", JSON.stringify({
            panel: "main"
        }));
    });

    $("#register_track").click(function() {
        $("#registerPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "track"
        }));
    });

    $("#register_ai").click(function() {
        $("#registerPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "ai"
        }));
    });

    $("#register_vlist").click(function() {
        $("#registerPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "list"
        }));
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

    document.onkeyup = function(data) {
        if (data.key == "Escape") {
            if (true == replyOpen) {
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
