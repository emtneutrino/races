/*

Copyright (c) 2021, Neil J. Tan
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
    let openPanel = ""

    $("#main").hide();
    $("#restricted").hide();
    $("#reply").hide();

    window.addEventListener("message", function(event) {
        let data = event.data;
        if ("main" == data.panel) {
            $("#buyin").val(data.defaultBuyin)
            $("#laps").val(data.defaultLaps)
            $("#timeout").val(data.defaultTimeout)
            $("#delay").val(data.defaultDelay)
            $("#vehicle0").val(data.defaultVehicle)
            $("#main").show();
            openPanel = "main"
        } else if ("restricted" == data.panel) {
            $("#vehicle1").val(data.defaultVehicle)
            $("#restricted").show();
            openPanel = "restricted"
        } else if ("reply" == data.panel) {
            if ("main" == openPanel) {
                $("#main").hide();
            } else if("restricted" == openPanel) {
                $("#restricted").hide();
            }
            document.getElementById("message").innerHTML = data.message;
            $("#reply").show();
            replyOpen = true;
        }
    });

    $("#edit").click(function() {
        $.post("https://races/edit");
    });

    $("#clear0").click(function() {
        $.post("https://races/clear");
    });

    $("#reverse").click(function() {
        $.post("https://races/reverse");
    });

    $("#load").click(function() {
        $.post("https://races/load", JSON.stringify({
            public: false,
            raceName: $("#name").val()
        }));
    });

    $("#save").click(function() {
        $.post("https://races/save", JSON.stringify({
            public: false,
            raceName: $("#name").val()
        }));
    });

    $("#overwrite").click(function() {
        $.post("https://races/overwrite", JSON.stringify({
            public: false,
            raceName: $("#name").val()
        }));
    });

    $("#delete").click(function() {
        $.post("https://races/delete", JSON.stringify({
            public: false,
            raceName: $("#name").val()
        }));
    });

    $("#blt").click(function() {
        $.post("https://races/blt", JSON.stringify({
            public: false,
            raceName: $("#name").val()
        }));
    });

    $("#list").click(function() {
        $.post("https://races/list", JSON.stringify({
            public: false
        }));
    });

    $("#loadPublic").click(function() {
        $.post("https://races/load", JSON.stringify({
            public: true,
            raceName: $("#namePublic").val()
        }));
    });

    $("#savePublic").click(function() {
        $.post("https://races/save", JSON.stringify({
            public: true,
            raceName: $("#namePublic").val()
        }));
    });

    $("#overwritePublic").click(function() {
        $.post("https://races/overwrite", JSON.stringify({
            public: true,
            raceName: $("#namePublic").val()
        }));
    });

    $("#deletePublic").click(function() {
        $.post("https://races/delete", JSON.stringify({
            public: true,
            raceName: $("#namePublic").val()
        }));
    });

    $("#bltPublic").click(function() {
        $.post("https://races/blt", JSON.stringify({
            public: true,
            raceName: $("#namePublic").val()
        }));
    });

    $("#listPublic").click(function() {
        $.post("https://races/list", JSON.stringify({
            public: true
        }));
    });

    $("#register").click(function() {
        $.post("https://races/register", JSON.stringify({
            buyin: $("#buyin").val(),
            laps: $("#laps").val(),
            timeout: $("#timeout").val(),
            rtype: $("#rtype").val(),
            restrict: $("#restrict").val(),
            filename: $("#filename").val(),
            vclass: $("#vclass0").val(),
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

    $("#leave0").click(function() {
        $.post("https://races/leave");
    });

    $("#rivals0").click(function() {
        $.post("https://races/rivals");
    });

    $("#respawn0").click(function() {
        $.post("https://races/respawn");
    });

    $("#results0").click(function() {
        $.post("https://races/results");
    });

    $("#spawn0").click(function() {
        $.post("https://races/spawn", JSON.stringify({
            vehicle: $("#vehicle0").val()
        }));
    });

    $("#lvehicles0").click(function() {
        $.post("https://races/lvehicles", JSON.stringify({
            vclass: $("#vclass1").val()
        }));
    });

    $("#speedo0").click(function() {
        $.post("https://races/speedo", JSON.stringify({
            unit: ""
        }));
    });

    $("#change0").click(function() {
        $.post("https://races/speedo", JSON.stringify({
            unit: $("#unit0").val()
        }));
    });

    $("#funds0").click(function() {
        $.post("https://races/funds");
    });

    $("#closeMain").click(function() {
        $("#main").hide();
        $.post("https://races/close");
    });

    $("#request").click(function() {
        $.post("https://races/request");
    });

    $("#clear1").click(function() {
        $.post("https://races/clear");
    });

    $("#leave1").click(function() {
        $.post("https://races/leave");
    });

    $("#rivals1").click(function() {
        $.post("https://races/rivals");
    });

    $("#respawn1").click(function() {
        $.post("https://races/respawn");
    });

    $("#results1").click(function() {
        $.post("https://races/results");
    });

    $("#spawn1").click(function() {
        $.post("https://races/spawn", JSON.stringify({
            vehicle: $("#vehicle1").val()
        }));
    });

    $("#lvehicles1").click(function() {
        $.post("https://races/lvehicles", JSON.stringify({
            vclass: $("#vclass2").val()
        }));
    });

    $("#speedo1").click(function() {
        $.post("https://races/speedo", JSON.stringify({
            unit: ""
        }));
    });

    $("#change1").click(function() {
        $.post("https://races/speedo", JSON.stringify({
            unit: $("#unit1").val()
        }));
    });

    $("#funds1").click(function() {
        $.post("https://races/funds");
    });

    $("#closeRestricted").click(function() {
        $("#restricted").hide();
        $.post("https://races/close");
    });

    $("#closeReply").click(function() {
        $("#reply").hide();
        if ("main" == openPanel) {
            $("#main").show();
        } else if("restricted" == openPanel) {
            $("#restricted").show();
        }
    });

    document.onkeyup = function(data) {
        if (data.key == "Escape") {
            if (true == replyOpen) {
                $("#reply").hide();
                replyOpen = false;
                if ("main" == openPanel) {
                    $("#main").show();
                } else if("restricted" == openPanel) {
                    $("#restricted").show();
                }
            } else {
                if ("main" == openPanel) {
                    $("#main").hide();
                } else if("restricted" == openPanel) {
                    $("#restricted").hide();
                }
                $.post("https://races/close");
            }
        }
    }
});