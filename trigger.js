/* Trigger code for thethings.io */


var impUrl = "agent.electricimp.com"
var impPath = "YOUR_AGENT?setled="

function trigger(params, callback) {
	var action = params["action"]
    var values = params["values"]
	console.log(params);
  	if (action == 'read') return callback()
	for (var i = 0; i < values.length; ++i) {
      if (values[i]['key'] != 'led') continue
	  var value = values[i]
	  console.log(value['key'])

      var request = 
        {
        	host: impUrl,
        	path: impPath + value['value'],
//          	port: 443,
        	method: "POST",
          	headers: {
		      'Content-Type':'application/json'
    		  }
	    }

      httpRequest(request, null, function(err, headers, data) {
        if (err) console.log(err)
        else console.log(data)
        return callback(null);
      })
    }
