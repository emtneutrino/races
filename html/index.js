/*

Copyright (c) 2022, Neil J. Tan
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
    $("#editPanel").hide();
    $("#registerPanel").hide();
    $("#aiPanel").hide();
    $("#listPanel").hide();
    $("#replyPanel").hide();

    window.addEventListener("message", function(event) {
        let data = event.data;
        if ("main" == data.panel) {
            $("#vehicle").val(data.defaultVehicle);
            $("#mainPanel").show();
            openPanel = "main";
        } else if ("edit" == data.panel) {
            $("#editPanel").show();
            openPanel = "edit";
        } else if ("register" == data.panel) {
            $("#buyin").val(data.defaultBuyin);
            $("#laps").val(data.defaultLaps);
            $("#timeout").val(data.defaultTimeout);
            $("#delay").val(data.defaultDelay);
            $("#rtype").change();
            $("#registerPanel").show();
            openPanel = "register";
        } else if ("ai" == data.panel) {
            $("#ai_vehicle").val(data.defaultVehicle);
            $("#aiPanel").show();
            openPanel = "ai";
        } else if ("list" == data.panel) {
            $("#listPanel").show();
            openPanel = "list";
        } else if ("reply" == data.panel) {
            $("#mainPanel").hide();
            $("#editPanel").hide();
            $("#registerPanel").hide();
            $("#aiPanel").hide();
            $("#listPanel").hide();
            document.getElementById("message").innerHTML = data.message;
            $("#replyPanel").show();
            replyOpen = true;
        } else if ("trackNames" == data.update) {
            if ("pvt" == data.access) {
                pvtTrackNames = data.trackNames;
            } else if ("pub" == data.access) {
                pubTrackNames = data.trackNames;
            };
            $("#main_track_access").change()
            $("#edit_track_access0").change()
            $("#register_track_access").change()
        } else if ("grpNames" == data.update) {
            if ("pvt" == data.access) {
                pvtGrpNames = data.grpNames;
            } else if ("pub" == data.access) {
                pubGrpNames = data.grpNames;
            };
            $("#grp_access0").change()
        } else if ("listNames" == data.update) {
            if ("pvt" == data.access) {
                pvtListNames = data.listNames;
            } else if ("pub" == data.access) {
                pubListNames = data.listNames;
            };
            $("#list_access0").change()
        } else if ("allVehicles" == data.update) {
            document.getElementById("all_veh_list").innerHTML = data.allVehicles;
        } else if ("vehicleList" == data.update) {
            document.getElementById("veh_list").innerHTML = data.vehicleList;
        };
    });

    /* main panel */
    $("#request").click(function() {
        $.post("https://races/request", JSON.stringify({
            role: $("#role").val()
        }));
    });

    $("#main_clear").click(function() {
        $.post("https://races/clear");
    });

    $("#main_track_access").change(function() {
        if ("pvt" == $("#main_track_access").val()) {
            document.getElementById("main_name").innerHTML = pvtTrackNames;
        } else {
            document.getElementById("main_name").innerHTML = pubTrackNames;
        }
    });

    $("#main_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            access: $("#main_track_access").val(),
            trackName: $("#main_name").val()
        }));
    });

    $("#main_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            access: $("#main_track_access").val(),
            trackName: $("#main_name").val()
        }));
    });

    $("#main_list").click(function() {
        $.post("https://races/list", JSON.stringify({
            access: $("#main_track_access").val()
        }));
    });

    $("#leave").click(function() {
        $.post("https://races/leave");
    });

    $("#rivals").click(function() {
        $.post("https://races/rivals");
    });

    $("#respawn").click(function() {
        $.post("https://races/respawn");
    });

    $("#results").click(function() {
        $.post("https://races/results");
    });

    $("#spawn").click(function() {
        $.post("https://races/spawn", JSON.stringify({
            vehicle: $("#vehicle").val()
        }));
    });

    $("#lvehicles").click(function() {
        $.post("https://races/lvehicles", JSON.stringify({
            vclass: $("#main_vclass").val()
        }));
    });

    $("#speedo").click(function() {
        $.post("https://races/speedo", JSON.stringify({
            unit: ""
        }));
    });

    $("#change").click(function() {
        $.post("https://races/speedo", JSON.stringify({
            unit: $("#unit").val()
        }));
    });

    $("#funds").click(function() {
        $.post("https://races/funds");
    });

    $("#main_edit").click(function() {
        $("#mainPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "edit"
        }));
    });

    $("#main_register").click(function() {
        $("#mainPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "register"
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

    $("#main_close").click(function() {
        $("#mainPanel").hide();
        $.post("https://races/close");
    });

    /* edit panel */
    $("#edit").click(function() {
        $.post("https://races/edit");
    });

    $("#edit_clear").click(function() {
        $.post("https://races/clear");
    });

    $("#edit_reverse").click(function() {
        $.post("https://races/reverse");
    });

    $("#edit_track_access0").change(function() {
        if ("pvt" == $("#edit_track_access0").val()) {
            document.getElementById("edit_name").innerHTML = pvtTrackNames;
        } else {
            document.getElementById("edit_name").innerHTML = pubTrackNames;
        }
    });

    $("#edit_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            access: $("#edit_track_access0").val(),
            trackName: $("#edit_name").val()
        }));
    });

    $("#edit_overwrite").click(function() {
        $.post("https://races/overwrite", JSON.stringify({
            access: $("#edit_track_access0").val(),
            trackName: $("#edit_name").val()
        }));
    });

    $("#edit_delete").click(function() {
        $.post("https://races/delete", JSON.stringify({
            access: $("#edit_track_access0").val(),
            trackName: $("#edit_name").val()
        }));
    });

    $("#edit_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            access: $("#edit_track_access0").val(),
            trackName: $("#edit_name").val()
        }));
    });

    $("#edit_list").click(function() {
        $.post("https://races/list", JSON.stringify({
            access: $("#edit_track_access0").val()
        }));
    });

    $("#edit_save").click(function() {
        $.post("https://races/save", JSON.stringify({
            access: $("#edit_track_access1").val(),
            trackName: $("#edit_unsaved").val()
        }));
    });

    $("#edit_main").click(function() {
        $("#editPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "main"
        }));
    });

    $("#edit_register").click(function() {
        $("#editPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "register"
        }));
    });

    $("#edit_ai").click(function() {
        $("#editPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "ai"
        }));
    });

    $("#edit_vlist").click(function() {
        $("#editPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "list"
        }));
    });

    $("#edit_close").click(function() {
        $("#editPanel").hide();
        $.post("https://races/close");
    });

    /* register panel */
    $("#register_track_access").change(function() {
        if ("pvt" == $("#register_track_access").val()) {
            document.getElementById("register_name").innerHTML = pvtTrackNames;
        } else {
            document.getElementById("register_name").innerHTML = pubTrackNames;
        }
    });

    $("#register_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            access: $("#register_track_access").val(),
            trackName: $("#register_name").val()
        }));
    });

    $("#register_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            access: $("#register_track_access").val(),
            trackName: $("#register_name").val()
        }));
    });

    $("#register_list").click(function() {
        $.post("https://races/list", JSON.stringify({
            access: $("#register_track_access").val()
        }));
    });

    $("#rtype").change(function() {
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
        if ($("#rtype").val() == "norm") {
            $("#rest").hide();
            $("#vclass").hide();
            $("#sveh").hide();
        } else if ($("#rtype").val() == "rest") {
            $("#rest").show();
            $("#vclass").hide();
            $("#sveh").hide();
        } else if ($("#rtype").val() == "class") {
            $("#rest").hide();
            document.getElementById("register_vclass").innerHTML = 
                "<option value = -1>-1:Custom</option>" +
                html;
            $("#vclass").show();
            $("#sveh").hide();
        } else if ($("#rtype").val() == "rand") {
            $("#rest").hide();
            document.getElementById("register_vclass").innerHTML = 
                "<option value = -2>Any</option>" +
                html;
            $("#vclass").show();
            $("#sveh").show();
        };
    });

    $("#register").click(function() {
        $.post("https://races/register", JSON.stringify({
            buyin: $("#buyin").val(),
            laps: $("#laps").val(),
            timeout: $("#timeout").val(),
            allowAI: $("#allowAI").val(),
            rtype: $("#rtype").val(),
            restrict: $("#restrict").val(),
            vclass: $("#register_vclass").val(),
            svehicle: $("#svehicle").val()
        }));
    });

    $("#unregister").click(function() {
        $.post("https://races/unregister");
    });

    $("#start").click(function() {
        $.post("https://races/start", JSON.stringify({
            delay: $("#delay").val()
        }));
    });

    $("#register_main").click(function() {
        $("#registerPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "main"
        }));
    });

    $("#register_edit").click(function() {
        $("#registerPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "edit"
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

/* AI panel */
    $("#add_ai").click(function() {
        $.post("https://races/add_ai", JSON.stringify({
            aiName: $("#ai_name").val()
        }));
    });

    $("#delete_ai").click(function() {
        $.post("https://races/delete_ai", JSON.stringify({
            aiName: $("#ai_name").val()
        }));
    });

    $("#spawn_ai").click(function() {
        $.post("https://races/spawn_ai", JSON.stringify({
            aiName: $("#ai_name").val(),
            vehicle: $("#ai_vehicle").val()
        }));
    });

    $("#list_ai").click(function() {
        $.post("https://races/list_ai");
    });

    $("#delete_all_ai").click(function() {
        $.post("https://races/delete_all_ai");
    });

    $("#grp_access0").change(function() {
        if ("pvt" == $("#grp_access0").val()) {
            document.getElementById("grp_name").innerHTML = pvtGrpNames;
        } else {
            document.getElementById("grp_name").innerHTML = pubGrpNames;
        }
    });

    $("#load_grp").click(function() {
        $.post("https://races/load_grp", JSON.stringify({
            access: $("#grp_access0").val(),
            name: $("#grp_name").val()
        }));
    });

    $("#overwrite_grp").click(function() {
        $.post("https://races/overwrite_grp", JSON.stringify({
            access: $("#grp_access0").val(),
            name: $("#grp_name").val()
        }));
    });

    $("#delete_grp").click(function() {
        $.post("https://races/delete_grp", JSON.stringify({
            access: $("#grp_access0").val(),
            name: $("#grp_name").val()
        }));
    });

    $("#list_grps").click(function() {
        $.post("https://races/list_grps", JSON.stringify({
            access: $("#grp_access0").val()
        }));
    });

    $("#save_grp").click(function() {
        $.post("https://races/save_grp", JSON.stringify({
            access: $("#grp_access1").val(),
            name: $("#grp_unsaved").val()
        }));
    });

    $("#ai_main").click(function() {
        $("#aiPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "main"
        }));
    });

    $("#ai_edit").click(function() {
        $("#aiPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "edit"
        }));
    });

    $("#ai_register").click(function() {
        $("#aiPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "register"
        }));
    });

    $("#ai_vlist").click(function() {
        $("#aiPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "list"
        }));
    });

    $("#ai_close").click(function() {
        $("#aiPanel").hide();
        $.post("https://races/close");
    });

    /* vehicle list panel */
    $("#add_veh").click(function() {
        $.post("https://races/add_veh", JSON.stringify({
            vehicle: $("#all_veh_list").val()
        }));
    });

    $("#delete_veh").click(function() {
        $.post("https://races/delete_veh", JSON.stringify({
            vehicle: $("#veh_list").val()
        }));
    });

    $("#add_class").click(function() {
        $.post("https://races/add_class", JSON.stringify({
            class: $("#list_vclass").val()
        }));
    });

    $("#delete_class").click(function() {
        $.post("https://races/delete_class", JSON.stringify({
            class: $("#list_vclass").val()
        }));
    });

    $("#add_all_veh").click(function() {
        $.post("https://races/add_all_veh");
    });

    $("#delete_all_veh").click(function() {
        $.post("https://races/delete_all_veh");
    });

    $("#list_veh").click(function() {
        $.post("https://races/list_veh");
    });

    $("#list_access0").change(function() {
        if ("pvt" == $("#list_access0").val()) {
            document.getElementById("list_name").innerHTML = pvtListNames;
        } else {
            document.getElementById("list_name").innerHTML = pubListNames;
        }
    });

    $("#load_list").click(function() {
        $.post("https://races/load_list", JSON.stringify({
            access: $("#list_access0").val(),
            name: $("#list_name").val()
        }));
    });

    $("#overwrite_list").click(function() {
        $.post("https://races/overwrite_list", JSON.stringify({
            access: $("#list_access0").val(),
            name: $("#list_name").val()
        }));
    });

    $("#delete_list").click(function() {
        $.post("https://races/delete_list", JSON.stringify({
            access: $("#list_access0").val(),
            name: $("#list_name").val()
        }));
    });

    $("#list_lists").click(function() {
        $.post("https://races/list_lists", JSON.stringify({
            access: $("#list_access0").val()
        }));
    });

    $("#save_list").click(function() {
        $.post("https://races/save_list", JSON.stringify({
            access: $("#list_access1").val(),
            name: $("#list_unsaved").val()
        }));
    });

    $("#vlist_main").click(function() {
        $("#listPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "main"
        }));
    });

    $("#vlist_edit").click(function() {
        $("#listPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "edit"
        }));
    });

    $("#vlist_register").click(function() {
        $("#listPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "register"
        }));
    });

    $("#vlist_ai").click(function() {
        $("#listPanel").hide();
        $.post("https://races/show", JSON.stringify({
            panel: "ai"
        }));
    });

    $("#list_close").click(function() {
        $("#listPanel").hide();
        $.post("https://races/close");
    });

    /* reply panel */
    $("#reply_close").click(function() {
        $("#replyPanel").hide();
        replyOpen = false;
        if ("main" == openPanel) {
            $("#mainPanel").show();
        } else if("edit" == openPanel) {
            $("#editPanel").show();
        } else if("register" == openPanel) {
            $("#registerPanel").show();
        } else if("ai" == openPanel) {
            $("#aiPanel").show();
        } else if("list" == openPanel) {
            $("#listPanel").show();
        };
    });

    document.onkeyup = function(data) {
        if (data.key == "Escape") {
            if (true == replyOpen) {
                $("#replyPanel").hide();
                replyOpen = false;
                if ("main" == openPanel) {
                    $("#mainPanel").show();
                } else if("edit" == openPanel) {
                    $("#editPanel").show();
                } else if("register" == openPanel) {
                    $("#registerPanel").show();
                } else if("ai" == openPanel) {
                    $("#aiPanel").show();
                } else if("list" == openPanel) {
                    $("#listPanel").show();
                };
            } else {
                $("#mainPanel").hide();
                $("#editPanel").hide();
                $("#registerPanel").hide();
                $("#aiPanel").hide();
                $("#listPanel").hide();
                $.post("https://races/close");
            };
        };
    };
});
