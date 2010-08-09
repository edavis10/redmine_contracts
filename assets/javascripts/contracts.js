jQuery(function($) {

  var right_align = $('#contract-terms .finance tr td:nth-child ~ td, .c_overview table.right tr td:nth-child ~ td, #deliverables table tr.click td:nth-child(5) ~ td, .deliverable_finance_table tr.aright td:nth-child ~ td');

  if (right_align.length > 0) {
    right_align.after().css("text-align", "right");
  }
	
	$("#deliverables table tbody tr td:contains('---')").css("text-align", "center");
	

	$(".texpand").jExpand();
	
	$(".texpand").find("tr.even").next('tr:first').addClass("even");
	
	$(window).resize(function() {
	
	});
	
	$('#expand_terms').click( function(){
		$(this).next().slideToggle();
		$(this).toggleClass('alt');
	}); 

  toggleSpecificDeliverableFields = function(form) {
    var deliverableType = form.find('.type').val();

    if (deliverableType == 'FixedDeliverable') {
      $('.deliverable_total_input').show();
    } else {
      $('.deliverable_total_input').
        children('input').val('').end().
        hide();
    }
  },

  toggleSpecificDeliverableFields($('form.deliverable'));

  $('select#deliverable_type').change(function() {
    toggleSpecificDeliverableFields($('form.deliverable'));
  });
});

/* Jquery Table Expander Plugin */
(function($){
    $.fn.jExpand = function(){
        var element = this;
        $(element).find("tr.ign").hide();

        $(element).find("tr.click").click(function() {
        	$(this).toggleClass("noborder");
            $(this).next("tr").toggle();
            $(this).find('.arrow').toggleClass("alt");
            
            var box_height = $(this).next().find('.expanded').height();
            var table_height = $(this).next().find('.finance table').height();
            
            if(box_height-table_height > 0){
            	$(this).next().find('.finance table .fill td').css("padding-top", box_height-table_height+2);
            }

        });
        
    }    
})(jQuery); 
