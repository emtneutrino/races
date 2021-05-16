$(function() {
    let replyOpen = false;

    $("#main").hide();
    $("#reply").hide();

    window.addEventListener("message", function(event) {
        let data = event.data;
        if ("main" == data.panel) {
            $("#main").show();
        } else {
            $("#main").hide();
            document.getElementById("message").innerHTML = data.message;
            $("#reply").show();
            replyOpen = true;
        }
    });

    $("#edit").click(function() {
        $.post("https://races/edit");
    });

    $("#clear").click(function() {
        $.post("https://races/clear");
    });

    $("#load").click(function() {
        let name = $("#name").val();
        $.post("https://races/load", JSON.stringify({
            public: false,
            raceName: name
        }));
    });

    $("#save").click(function() {
        let name = $("#name").val();
        $.post("https://races/save", JSON.stringify({
            public: false,
            raceName: name
        }));
    });

    $("#overwrite").click(function() {
        let name = $("#name").val();
        $.post("https://races/overwrite", JSON.stringify({
            public: false,
            raceName: name
        }));
    });

    $("#delete").click(function() {
        let name = $("#name").val();
        $.post("https://races/delete", JSON.stringify({
            public: false,
            raceName: name
        }));
    });

    $("#blt").click(function() {
        let name = $("#name").val();
        $.post("https://races/blt", JSON.stringify({
            public: false,
            raceName: name
        }));
    });

    $("#list").click(function() {
        $.post("https://races/list", JSON.stringify({
            public: false
        }));
    });

    $("#loadPublic").click(function() {
        let name = $("#namePublic").val();
        $.post("https://races/load", JSON.stringify({
            public: true,
            raceName: name
        }));
    });

    $("#savePublic").click(function() {
        let name = $("#namePublic").val();
        $.post("https://races/save", JSON.stringify({
            public: true,
            raceName: name
        }));
    });

    $("#overwritePublic").click(function() {
        let name = $("#namePublic").val();
        $.post("https://races/overwrite", JSON.stringify({
            public: true,
            raceName: name
        }));
    });

    $("#deletePublic").click(function() {
        let name = $("#namePublic").val();
        $.post("https://races/delete", JSON.stringify({
            public: true,
            raceName: name
        }));
    });

    $("#bltPublic").click(function() {
        let name = $("#namePublic").val();
        $.post("https://races/blt", JSON.stringify({
            public: true,
            raceName: name
        }));
    });

    $("#listPublic").click(function() {
        $.post("https://races/list", JSON.stringify({
            public: true
        }));
    });

    $("#register").click(function() {
        let laps = $("#laps").val();
        let timeout = $("#timeout").val();
        $.post("https://races/register", JSON.stringify({
            laps: laps,
            timeout: timeout
        }));
    });

    $("#unregister").click(function() {
        $.post("https://races/unregister");
    });

    $("#leave").click(function() {
        $.post("https://races/leave");
    });

    $("#rivals").click(function() {
        $.post("https://races/rivals");
    });

    $("#start").click(function() {
        let delay = $("#delay").val();
        $.post("https://races/start", JSON.stringify({
            delay: delay
        }));
    });

    $("#results").click(function() {
        $.post("https://races/results");
    });

    $("#speedo").click(function() {
        $.post("https://races/speedo");
    });

    $("#car").click(function() {
        let carName = $("#carName").val();
        $.post("https://races/car", JSON.stringify({
            carName: carName
        }));
    });
    
    $("#closeMain").click(function() {
        $("#main").hide();
        $.post("https://races/close");
    });

    $("#closeReply").click(function() {
        $("#reply").hide();
        replyOpen = false;
        $("#main").show();
    });

    document.onkeyup = function(data) {
        if (data.key == "Escape") {
            if (true == replyOpen) {
                $("#reply").hide();
                replyOpen = false;
                $("#main").show();
            } else {
                $("#main").hide();
                $.post("https://races/close");
            }
        }
    }
});