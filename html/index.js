$(function () {
    function showMain(show) {
        if (true == show) {
            $("#main").show();
        } else {
            $("#main").hide();
        }
    }

    showMain(false)

    window.addEventListener("message", function(event) {
        showMain(event.data.show)
    })

    $("#edit").click(function() {
        $.post("https://races/edit");
        return
    })

    $("#clear").click(function() {
        $.post("https://races/clear");
        return
    })

    $("#load").click(function() {
        let name = $("#name").val()
        $.post("https://races/load", JSON.stringify({
            public: false,
            raceName: name
        }));
        return
    })

    $("#save").click(function() {
        let name = $("#name").val()
        $.post("https://races/save", JSON.stringify({
            public: false,
            raceName: name
        }));
        return
    })

    $("#overwrite").click(function() {
        let name = $("#name").val()
        $.post("https://races/overwrite", JSON.stringify({
            public: false,
            raceName: name
        }));
        return
    })

    $("#delete").click(function() {
        let name = $("#name").val()
        $.post("https://races/delete", JSON.stringify({
            public: false,
            raceName: name
        }));
        return
    })

    $("#blt").click(function() {
        let name = $("#name").val()
        $.post("https://races/blt", JSON.stringify({
            public: false,
            raceName: name
        }));
        return
    })

    $("#list").click(function() {
        $.post("https://races/list", JSON.stringify({
            public: false
        }));
        return
    })

    $("#loadPublic").click(function() {
        let name = $("#namePublic").val()
        $.post("https://races/load", JSON.stringify({
            public: true,
            raceName: name
        }));
        return
    })

    $("#savePublic").click(function() {
        let name = $("#namePublic").val()
        $.post("https://races/save", JSON.stringify({
            public: true,
            raceName: name
        }));
        return
    })

    $("#overwritePublic").click(function() {
        let name = $("#namePublic").val()
        $.post("https://races/overwrite", JSON.stringify({
            public: true,
            raceName: name
        }));
        return
    })

    $("#deletePublic").click(function() {
        let name = $("#namePublic").val()
        $.post("https://races/delete", JSON.stringify({
            public: true,
            raceName: name
        }));
        return
    })

    $("#bltPublic").click(function() {
        let name = $("#namePublic").val()
        $.post("https://races/blt", JSON.stringify({
            public: true,
            raceName: name
        }));
        return
    })

    $("#listPublic").click(function() {
        $.post("https://races/list", JSON.stringify({
            public: true
        }));
        return
    })

    $("#register").click(function() {
        let laps = $("#laps").val()
        let timeout = $("#timeout").val()
        $.post("https://races/register", JSON.stringify({
            laps: laps,
            timeout: timeout
        }));
        return
    })

    $("#unregister").click(function() {
        $.post("https://races/unregister");
        return
    })

    $("#leave").click(function() {
        $.post("https://races/leave");
        return
    })

    $("#rivals").click(function() {
        $.post("https://races/rivals");
        return
    })

    $("#start").click(function() {
        let delay = $("#delay").val()
        $.post("https://races/start", JSON.stringify({
            delay: delay
        }));
        return
    })

    $("#results").click(function() {
        $.post("https://races/results");
        return
    })

    $("#speedo").click(function() {
        $.post("https://races/speedo");
        return
    })

    $("#car").click(function() {
        let carName = $("#carName").val()
        $.post("https://races/car", JSON.stringify({
            carName: carName
        }));
        return
    })
    
    $("#close").click(function() {
        $.post("https://races/close");
        return
    })

    document.onkeyup = function(data) {
        if (data.key == "Escape") {
            $.post("https://races/close");
            return
        }
    }
})