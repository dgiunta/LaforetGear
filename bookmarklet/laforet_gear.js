var LaforetGear = (function($) {
	var currentPage,
			priceTemplate = "<span class='price'>{{price}}</span>";

	function init (path) {
		currentPage = ( path || window.location.pathname ).replace(/^\/mygear\/|\/$/g, '');
		loadJSON();
	}

	function loadJSON () {
		$.ajax({
			url: 'http://davegiunta.com/laforet_gear/' + currentPage + '.json',
			success: insertPrices,
			dataType: 'jsonp'
		});
	}

	function insertPrices (data) {
		var total = 0.0;

		$.each(data.prices, function(url, price) {
			$('a[href=' + url + ']').prepend(priceElement(price));
		});

		$('.post-body table').each(function(i, table) {
			var prices = $('span.price', table).map(function(i, span) {
						return parseFloat(span.innerHTML.replace(/\$/, ''), 10);
					}).toArray(),

					lowestPrice = prices.sort(function(a, b) {
						return a > b ? 1 : -1;
					})[0];

			if (lowestPrice) { total += lowestPrice; }
		});

		$('.post-title h1').append(priceElement('$' + total.toFixed(2)));
	}

	function priceElement (price) {
		return priceTemplate.replace(/\{\{\w*\}\}/, price);
	}

	return {init: init};
})(jQuery);
