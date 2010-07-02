jQuery(function($) {
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
