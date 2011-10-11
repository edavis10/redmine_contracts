jQuery(function($) {
  $("#ajax-indicator").ajaxStart(function(){ $(this).show();  });
  $("#ajax-indicator").ajaxStop(function(){ $(this).hide();  });

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

		var new_height = $('#contract-terms .info').height() - $('#contract-terms .finance').height() + 30;
		$('#contract-terms .stretch').css('height', new_height);
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
      $('#retainer-finances-message').hide();
    } else if(deliverableType == "HourlyDeliverable") {
      hideDeliverableTotal();
      hideDeliverableFrequency();
      $('#retainer-finances-message').hide();
    } else if(deliverableType == "RetainerDeliverable") {
      hideDeliverableTotal();
      showDeliverableFrequency();
      if ($('form.deliverable #deliverable_stored_id').val() == '') {
        $('#retainer-finances-message').show();
      } else {
        $('#retainer-finances-message').hide();
      }

   }
  },

  showDeliverableAddButtons = function() {
    var laborLinks = $('table.deliverable_finance_table .add-labor a.add')
    if (laborLinks.length == 0) {
      // No link, add a blank form
      addNewDeliverableLaborItem();
    } else {
      laborLinks.hide().last().show();
    }
    var overheadLinks = $('table.deliverable_finance_table .add-overhead a.add')
    if (overheadLinks.length == 0) {
      // No link, add a blank form
      addNewDeliverableOverheadItem();
    } else {
      overheadLinks.hide().last().show();
    }
  },

  addNewDeliverableLaborItem = function() {
    addNewDeliverableFinance('#labor-budget-template',
                             '#deliverable-labor tbody',
                             $("tr.labor-budget-form").size(),
                             'labor-budget-form');
  },

  addNewDeliverableOverheadItem = function() {
    addNewDeliverableFinance('#overhead-budget-template',
                             '#deliverable-overhead tbody',
                             $("tr.overhead-budget-form").size(),
                             'overhead-budget-form');
  },

  addNewDeliverableFinance = function(templateSelector, appendTemplateTo, countOfExisting, rowClass) {
    var t = $(templateSelector).tmpl({});
    if (t.length > 0) {
      var recordLocation = countOfExisting + 1; // increments the Rails [n] placeholder
      var newContent = t.html().replace(/\[0\]/g, "[" + recordLocation + "]"); 

      $("<tr class='" + rowClass + "'>" + newContent + '</tr>').appendTo(appendTemplateTo);
      showDeliverableAddButtons();
    }
  },

  // Set the deleted flag for Rails and move it out of the row into
  // a hidden table
  deleteDeliverableFinance = function(deleteLink) {
    if (confirm(i18nAreYouSure)) {
      $(deleteLink).parent().find('.delete-flag').val('1')
      if ($('#deleted-finances').length == 0) {
        $(deleteLink).
          closest("form").
          append($("<table style='display:none' id='deleted-finances'></table>"));
      }
      $('#deleted-finances').append(
        $(deleteLink). // <a>
        parent(). // <td>
        parent().hide()
      ); // <tr>
      showDeliverableAddButtons();
    }
  },

  showDeliverableAddButtons();
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

      if ($('form.deliverable #deliverable_stored_id').val() != '') {
        if ($('form.deliverable .start-date').val() != $('#deliverable_stored_start_date').val()) {
          return confirm(i18nChangedPeriodMessage);
        }
        if ($('form.deliverable .end-date').val() != $('#deliverable_stored_end_date').val()) {
          return confirm(i18nChangedPeriodMessage);
        }
      }

    }
  });

  $('select.retainer_period_change').live('change', function() {
    var deliverable_url = $(this).closest('form').attr('action');
    $(this).closest('tr').load(deliverable_url, this.form.serialize());
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
