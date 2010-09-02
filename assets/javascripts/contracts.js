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

  showDeliverableTotal = function() {
    $('.deliverable_total_input').show();
  },

  hideDeliverableTotal = function() {
    $('.deliverable_total_input').
      children('input').val('').end().
      hide();
  },

  showDeliverableFrequency = function() {
    $('#deliverable_frequency').show();
  },

  hideDeliverableFrequency = function() {
    $('#deliverable_frequency').hide();
  },

  toggleSpecificDeliverableFields = function(form) {
    var deliverableType = form.find('.type').val();

    if (deliverableType == 'FixedDeliverable') {
      showDeliverableTotal();
      hideDeliverableFrequency();
    } else if(deliverableType == "HourlyDeliverable") {
      hideDeliverableTotal();
      hideDeliverableFrequency();
    } else if(deliverableType == "RetainerDeliverable") {
      hideDeliverableTotal();
      showDeliverableFrequency();
   }
  },

  toggleSpecificDeliverableFields($('form.deliverable'));

  $('select#deliverable_type').change(function() {
    toggleSpecificDeliverableFields($('form.deliverable'));
  });

  $('form.deliverable').submit(function() {
    var deliverableType = $('form.deliverable').find('.type').val();

    if (deliverableType == 'RetainerDeliverable') {
      if ($('form.deliverable .start-date[value!=""]').length == 0) {
        return confirm(i18nStartDateEmpty);
      }
      if ($('form.deliverable .end-date[value!=""]').length == 0) {
        return confirm(i18nEndDateEmpty);
      }
    }
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
