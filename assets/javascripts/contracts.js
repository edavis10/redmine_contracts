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
    var fixedLinks = $('#deliverable-fixed .fixed-budget-form .add-fixed a.add')
    if (fixedLinks.length == 0) {
      // No link, add a blank form
      addNewDeliverableFixedItem();
    } else {
      fixedLinks.hide().last().show();
    }
  },

  addNewDeliverableLaborItem = function() {
    addNewDeliverableFinance('#labor-budget-template',
                             '#deliverable-labor tbody',
                             $("tr.labor-budget-form").size(),
                             '<tr class="labor-budget-form">');
  },

  addNewDeliverableOverheadItem = function() {
    addNewDeliverableFinance('#overhead-budget-template',
                             '#deliverable-overhead tbody',
                             $("tr.overhead-budget-form").size(),
                             '<tr class="overhead-budget-form">');
  },

  addNewDeliverableFixedItem = function() {
    addNewDeliverableFinance('#fixed-budget-template',
                             '#deliverable-fixed.fixed-item-form',
                             $("div.fixed-budget-form").size(),
                             '<div class="fixed-budget-form">');
  },

  addNewDeliverableFinance = function(templateSelector, appendTemplateTo, countOfExisting, wrapperElement) {
    var t = $(templateSelector).tmpl({});
    if (t.length > 0) {
      var recordLocation = countOfExisting + 1; // increments the Rails [n] placeholder
      var newContent = t.html().replace(/\[0\]/g, "[" + recordLocation + "]");
      // New ids for textareas for the jsToolBar to attach to
      newContent = newContent.replace(/fixed-description\d*/g, "fixed-description" + Math.floor(Math.random() * 100000000))
      var newItem = $(wrapperElement).html(newContent)

      newItem.appendTo(appendTemplateTo);
      newItem.find("textarea.wiki-edit").each(function () {
        attachWikiToolbar(this.id);
      });
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

  // Add a div for jquery UI windows. Need to check because other plugins
  // use the same element id for the same purpose.
  //
  // TODO: add dialog-window to ChiliProject core
  if ($('#dialog-window').length == 0) {
    $("<div id='dialog-window'>").appendTo('body');
  }

  $('.deliverable-lightbox').live('click', function() {
    var deliverableId = $(this).data('deliverable-id');

    $('#dialog-window').
      hide().
      html('<h2>Hello</h2><p>This is a report for Deliverable #' + deliverableId + '.</p>').
      dialog({
        title: "",
        minWidth: 400,
        width: 850,
        buttons: {
          "Close": function() {
            $(this).dialog("close");
          }
        }
      });

    return false;
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

// Global functions outside of jQuery scoping
function attachWikiToolbar(id) {
  var jsToolBarInstance = new jsToolBar($(id));
  jsToolBarInstance.draw();
}
