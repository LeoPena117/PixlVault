$("#usedUsername").hide();
$("#changeUName").on('click',function(){
	$("#tBox").show()
})


$("#tBox").on('blur', function() {

	username = $("#tBox").val();
	$.ajax({
		method : "POST",
		url : "/changeUname",
			dataType : "text",
		data:{
        	username: username
        }}).done(function(data){
			if(data!=null){
        	data=JSON.parse(data)
        	console.log(data)
        	if(data.success==false){
        		$("#usedUsername").show();
        	}
        	else{
        		$("#usedUsername").hide();
				$("username").text(data)
				$("#tBox").hide()
				location.reload()
			}
			}

        })

})