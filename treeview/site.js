var createTextNode = function (text) {
	var span = document.createElement("span");
	
	var tx = document.createTextNode(text);
	span.appendChild(tx);

	span.setAttribute("style", "margin-left: 4px");
	return span;
};
 		
var fileBuilder = function(obj, examesNode){
 	var examNode = document.createElement("li");
	
	examNode.className = "open";					
	span = document.createElement("span");
	span.className = "file";
	span.appendChild(createTextNode(obj.id + "  " + obj.Name));
	
	examNode.appendChild(span);
	examesNode.appendChild(examNode);	
}

var folderBuilder = function(obj, classesNode){
	$.each(obj, function (i, aClass) {  

        	var classNode = document.createElement("li");
        	classNode.className = "open";
        	span = document.createElement("span");
        	span.className = obj[i].Nodes ? "folder" : "file"

        	span.appendChild(createTextNode(aClass.id + " " + aClass.Name))
        	classNode.appendChild(span);
       		var examesNode = document.createElement("ul"); 
        	examesNode.className = obj[i].Nodes ? "folder" : "file"; 
					
		if( obj[i].Nodes ){ 
		
			classNode.appendChild(examesNode);
                    	classesNode.appendChild(classNode);
			folderBuilder(aClass.Nodes, examesNode);
		
		}  else {
 
			fileBuilder(aClass, examesNode);
                    	classesNode.appendChild(classNode);
		}
					
	});	
}
	
		
var buildTree = function (nodes) {
 
	var root = document.createElement("ul");
	root.id = "TreeRoot";
	root.className = "filetree";
	
	$.each(nodes.Nodes, function (i, node) { 
		
		var newNode = document.createElement("li");
		newNode.className = "open";

		var span = document.createElement("span");
		span.className = node.Nodes ? "folder" : "file";
		span.appendChild(createTextNode(node.id+ " " +node.Name));
		newNode.appendChild(span);

		var classesNode = document.createElement("ul"); 
		
		if( node.Nodes )
			folderBuilder(node.Nodes, classesNode);

		newNode.appendChild(classesNode);
		root.appendChild(newNode);
	});

	$("#Tree").html("").append(root);
	$("#TreeRoot").treeview({
 		collapsed: false
	});
};
function loadJSON(callback) {   

    var xobj = new XMLHttpRequest();
    xobj.overrideMimeType("application/json");
    xobj.open('GET', 'http://127.0.0.1:8887/data.json', true); 
    xobj.onreadystatechange = function () {
	   if (xobj.readyState == 4 && xobj.status == 200) {
           	callback(xobj.responseText);
           }
    };
    xobj.send(null);  
 }

function loadFile() {
	var input, file, fr;

	if (typeof window.FileReader !== 'function') {
		alert("Ta aplikacja nie jest suportowana przez t¹ przegl¹darkê.");
		return;
	}

	input = document.getElementById('fileinput');
	if (!input) {
		alert("Nie mogê znaleŸæ wyspecyfikowanego pliku");
	} else if (!input.files) {
		alert("Ta przegl¹darka chyba nie wspiera protoko³u file:");
	} else if (!input.files[0]) {
		alert("Najpierw wybierz plik a póŸniej naciœnij 'Za³aduj'");
	}else {
		file = input.files[0];
		fr = new FileReader();
		fr.onload = receivedText;
		fr.readAsText(file);
	}

	function receivedText(e) {
		let lines = e.target.result;
		$("#Tree").html("");

		try {
			var dataObj = JSON.parse(lines); 
    		} catch(ex){
     			alert("B³¹d przy odczycie pliku JSON.");
   		}
		try {
			buildTree( dataObj );	
    		} catch(ex){
     			alert("B³¹d podczas budowy dzrewa JSON.");
   		}
	}
}
 

