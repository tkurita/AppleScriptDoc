function plog(msg) {
    document.write('<p>'+msg+'</p>');
}

function resolveScriptPath() {
    var link_path = document.getElementById('helpviewer-handler-helper').href;
    var root_abs = document.getElementById('HelpBookRoot').href;
    var script_path = link_path.substr(root_abs.length);
    var path_elems = root_abs.split('/');
    var helpbook_id = path_elems.pop();
    if (helpbook_id.length == 0) {
        helpbook_id = path_elems.pop();
    }
    script_path = helpbook_id+'/'+script_path;
    return script_path;
}

function processScriptLink(link) {
    var script_path = resolveScriptPath();
    var helpscript_url = "help:runscript='"+script_path+"' string='"+link+"'";
    document.location = helpscript_url;
}

function setupHelpViewerHandlerEnable() {
    var script_buttons = document.getElementsByClassName('scriptButton');
    for (n = 0; n < script_buttons.length; n++) {
        var a_button = script_buttons[n];
        var button_parts = a_button.children;
        for (m = 0; m < button_parts.length; m++) {
            var input_elem = button_parts[m];
            if (input_elem.src && input_elem.src.match(/^applescript:/)) {
                input_elem.addEventListener("click", function() {processScriptLink(this.src)}, true);
            }
        }
    }
}

if (window.navigator.userAgent.indexOf('Help Viewer') > 0) {
    window.addEventListener("load", setupHelpViewerHandlerEnable, true);
}