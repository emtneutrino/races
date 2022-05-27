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

    $("#mainPanel").hide();
    $("#editPanel").hide();
    $("#registerPanel").hide();
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
            $("#ai_vehicle").val(data.defaultVehicle);
            $("#rtype").change();
            $("#registerPanel").show();
            openPanel = "register";
        } else if ("reply" == data.panel) {
            $("#mainPanel").hide();
            $("#editPanel").hide();
            $("#registerPanel").hide();
            document.getElementById("message").innerHTML = data.message;
            $("#replyPanel").show();
            replyOpen = true;
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

    $("#main_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            isPublic: false,
            trackName: $("#main_name").val()
        }));
    });

    $("#main_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            isPublic: false,
            trackName: $("#main_name").val()
        }));
    });

    $("#main_list").click(function() {
        $.post("https://races/list", JSON.stringify({
            isPublic: false
        }));
    });

    $("#main_load_pub").click(function() {
        $.post("https://races/load", JSON.stringify({
            isPublic: true,
            trackName: $("#main_name_pub").val()
        }));
    });

    $("#main_blt_pub").click(function() {
        $.post("https://races/blt", JSON.stringify({
            isPublic: true,
            trackName: $("#main_name_pub").val()
        }));
    });

    $("#main_list_pub").click(function() {
        $.post("https://races/list", JSON.stringify({
            isPublic: true
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

    $("#edit_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            isPublic: false,
            trackName: $("#edit_name").val()
        }));
    });

    $("#edit_save").click(function() {
        $.post("https://races/save", JSON.stringify({
            isPublic: false,
            trackName: $("#edit_name").val()
        }));
    });

    $("#edit_overwrite").click(function() {
        $.post("https://races/overwrite", JSON.stringify({
            isPublic: false,
            trackName: $("#edit_name").val()
        }));
    });

    $("#edit_delete").click(function() {
        $.post("https://races/delete", JSON.stringify({
            isPublic: false,
            trackName: $("#edit_name").val()
        }));
    });

    $("#edit_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            isPublic: false,
            trackName: $("#edit_name").val()
        }));
    });

    $("#edit_list").click(function() {
        $.post("https://races/list", JSON.stringify({
            isPublic: false
        }));
    });

    $("#edit_load_pub").click(function() {
        $.post("https://races/load", JSON.stringify({
            isPublic: true,
            trackName: $("#edit_name_pub").val()
        }));
    });

    $("#edit_save_pub").click(function() {
        $.post("https://races/save", JSON.stringify({
            isPublic: true,
            trackName: $("#edit_name_pub").val()
        }));
    });

    $("#edit_overwrite_pub").click(function() {
        $.post("https://races/overwrite", JSON.stringify({
            isPublic: true,
            trackName: $("#edit_name_pub").val()
        }));
    });

    $("#edit_delete_pub").click(function() {
        $.post("https://races/delete", JSON.stringify({
            isPublic: true,
            trackName: $("#edit_name_pub").val()
        }));
    });

    $("#edit_blt_pub").click(function() {
        $.post("https://races/blt", JSON.stringify({
            isPublic: true,
            trackName: $("#edit_name_pub").val()
        }));
    });

    $("#edit_list_pub").click(function() {
        $.post("https://races/list", JSON.stringify({
            isPublic: true
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

    $("#edit_close").click(function() {
        $("#editPanel").hide();
        $.post("https://races/close");
    });

    /* register panel */
    $("#register_load").click(function() {
        $.post("https://races/load", JSON.stringify({
            isPublic: false,
            trackName: $("#register_name").val()
        }));
    });

    $("#register_blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            isPublic: false,
            trackName: $("#register_name").val()
        }));
    });

    $("#register_list").click(function() {
        $.post("https://races/list", JSON.stringify({
            isPublic: false
        }));
    });

    $("#register_load_pub").click(function() {
        $.post("https://races/load", JSON.stringify({
            isPublic: true,
            trackName: $("#register_name_pub").val()
        }));
    });

    $("#register_blt_pub").click(function() {
        $.post("https://races/blt", JSON.stringify({
            isPublic: true,
            trackName: $("#register_name_pub").val()
        }));
    });

    $("#register_list_pub").click(function() {
        $.post("https://races/list", JSON.stringify({
            isPublic: true
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
            $("#file").hide();
            $("#vclass").hide();
            $("#sveh").hide();
        } else if ($("#rtype").val() == "rest") {
            $("#rest").show();
            $("#file").hide();
            $("#vclass").hide();
            $("#sveh").hide();
        } else if ($("#rtype").val() == "class") {
            $("#rest").hide();
            if ($("#register_vclass").val() == "-1") {
                $("#file").show();
            } else {
                $("#file").hide();
            };
            document.getElementById("register_vclass").innerHTML = 
                "<option value = -2>Any</option>" +
                "<option value = -1>-1:Custom</option>" +
                html;
            $("#vclass").show();
            $("#sveh").hide();
        } else if ($("#rtype").val() == "rand") {
            $("#rest").hide();
            $("#file").show();
            document.getElementById("register_vclass").innerHTML = 
                "<option value = -2>Any</option>" +
                html;
            $("#vclass").show();
            $("#sveh").show();
        };
    });

    $("#register_vclass").change(function() {
        if ($("#rtype").val() == "class") {
            if ($("#register_vclass").val() == "-1") {
                $("#file").show();
            } else {
                $("#file").hide();
            };
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
            filename: $("#filename").val(),
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

    $("#load_grp").click(function() {
        $.post("https://races/load_grp", JSON.stringify({
            isPublic: false,
            name: $("#ai_grp_name").val()
        }));
    });

    $("#save_grp").click(function() {
        $.post("https://races/save_grp", JSON.stringify({
            isPublic: false,
            name: $("#ai_grp_name").val()
        }));
    });

    $("#overwrite_grp").click(function() {
        $.post("https://races/overwrite_grp", JSON.stringify({
            isPublic: false,
            name: $("#ai_grp_name").val()
        }));
    });

    $("#delete_grp").click(function() {
        $.post("https://races/delete_grp", JSON.stringify({
            isPublic: false,
            name: $("#ai_grp_name").val()
        }));
    });

    $("#list_grp").click(function() {
        $.post("https://races/list_grp", JSON.stringify({
            isPublic: false
        }));
    });

    $("#load_grp_pub").click(function() {
        $.post("https://races/load_grp", JSON.stringify({
            isPublic: true,
            name: $("#ai_grp_name_pub").val()
        }));
    });

    $("#save_grp_pub").click(function() {
        $.post("https://races/save_grp", JSON.stringify({
            isPublic: true,
            name: $("#ai_grp_name_pub").val()
        }));
    });

    $("#overwrite_grp_pub").click(function() {
        $.post("https://races/overwrite_grp", JSON.stringify({
            isPublic: true,
            name: $("#ai_grp_name_pub").val()
        }));
    });

    $("#delete_grp_pub").click(function() {
        $.post("https://races/delete_grp", JSON.stringify({
            isPublic: true,
            name: $("#ai_grp_name_pub").val()
        }));
    });

    $("#list_grp_pub").click(function() {
        $.post("https://races/list_grp", JSON.stringify({
            isPublic: true
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
        } else if("edit" == openPanel) {
            $("#editPanel").show();
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
                } else if("edit" == openPanel) {
                    $("#editPanel").show();
                } else if("register" == openPanel) {
                    $("#registerPanel").show();
                };
            } else {
                $("#mainPanel").hide();
                $("#editPanel").hide();
                $("#registerPanel").hide();
                $.post("https://races/close");
            };
        };
    };
});
