function check_helpviewer()
{
	a_flag = window.navigator.userAgent.indexOf('Help Viewer') > 0;
	if (!a_flag) {
		alert('This link works only in Help Viewer.')
	}
	return a_flag
}

function plog(msg) {
	document.write('<p>'+msg+'</p>');
}

function scriptPath(linkref) {
	link_path = linkref.href;
	root_abs = document.getElementById('HelpBookRoot').href;
	script_path = link_path.substr(root_abs.length);
    path_elems = root_abs.split('/');
    helpbook_id = path_elems.pop();
    if (helpbook_id.length == 0) {
		helpbook_id = path_elems.pop();
    }
    script_path = helpbook_id+'/'+script_path;
    return script_path;
}

function bundleRoot() {
    doc_path = document.location.pathname;
    path_elems = doc_path.split('/Contents/Resources');
    bundle_root = path_elems.shift();
    return bundle_root;
}

function runHelpScriptWithBundleRoot(linkref) {
    if (!check_helpviewer()) {
        return false;
    }
    script_path = scriptPath(linkref);
    bundle_root = bundleRoot();
    helpscript_url = "help:runscript='"+script_path+"' string='"+bundle_root+"'";
    document.location = helpscript_url;
    return false;
}

function runHelpScript(linkref) {
	if (!check_helpviewer()) {
	    return false;
	}
	script_path = scriptPath(linkref);
	helpscript_url = "help:runscript='"+script_path+"'";
	document.location = helpscript_url;
	
	return false;
}

function runHelpScriptWithInnerText(linkref) {
	if (!check_helpviewer()) {
		return false;
	}
	script_path = scriptPath(linkref);
	helpscript_url = "help:runscript='"+script_path+"' string='"+linkref.parentNode.innerText+"'";
	document.location = helpscript_url;
	return false;
}