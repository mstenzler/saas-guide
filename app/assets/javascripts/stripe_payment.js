jQuery(function($) {
  $('#payment-form').submit(function(event) {
    var $form = $(this);
    console.log("in submit");

    // Disable the submit button to prevent repeated clicks
    $form.find('button').prop('disabled', true);
    console.log("Disabled button");

    Stripe.card.createToken($form, stripeResponseHandler);

    // Prevent the form from submitting with the default action
    return false;
  });

  function stripeResponseHandler(status, response) {
	  var $form = $('#payment-form');
	  console.log("In stripeResponseHandler");

	  if (response.error) {
	  	console.log("Got error: ");
	  	console.log(response.error);
	    // Show the errors on the form
	    $form.find('.payment-errors').text(response.error.message);
	    $form.find('button').prop('disabled', false);
	  } else {
	    // response contains id and card, which contains additional card details
	    var token = response.id;
	    console.log("token = " + token);
	    // Insert the token into the form so it gets submitted to the server
	    $form.append($('<input type="hidden" name="stripeToken" />').val(token));
	    // and submit
	    $form.get(0).submit();
	  }
	};
});