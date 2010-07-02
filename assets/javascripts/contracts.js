jQuery(function($) {
  toggleSpecificDeliverableFields = function() {
    var deliverableType = $('select#deliverable_type option:selected').val();

    if (deliverableType == 'FixedDeliverable') {
      $('#deliverable_total_input').show();
    } else {
      $('#deliverable_total_input').
        children('#deliverable_total').val('').end().
        hide();
    }
  },

  toggleSpecificDeliverableFields();

  $('select#deliverable_type').change(function() {
    toggleSpecificDeliverableFields();
  });
});
