describe('LaforetGear', function() {
	describe('getting remote json', function() {
		var ajaxArgs;

		beforeEach(function() {
			spyOn($, 'ajax');
			LaforetGear.init('/mygear/cameras/');
			ajaxArgs = $.ajax.argsForCall[0][0];
		});
		
		it('sends a jsonp request to davegiunta.com/laforet_gear/cameras.json', function() {
			expect($.ajax).toHaveBeenCalled();
			expect(ajaxArgs.url).toEqual('http://davegiunta.com/laforet_gear/cameras.json');
			expect(ajaxArgs.dataType).toEqual('jsonp');
		});

		describe('inserting prices', function() {
			var fixture, success, 
					googleLink, bhLink1, bhLink2, header,
					data = {
						prices: {
							'http://www.google.com': '$10.95',
							'http://www.bhphotovideo.com/1': '$15.55',
							'http://www.bhphotovideo.com/2': '$25.55'
						}
					};

			beforeEach(function() {
				setupPage();
				success = ajaxArgs.success;
				success(data);
			});

			afterEach(teardownPage);

			it('inserts a span with the price into the appropriate anchor tag', function() {
				var span = $('span.price', googleLink);
				expect(span.length).toEqual(1);
				expect(span.text()).toEqual('$10.95');
			});

			it('inserts a total price in the header of the page', function() {
				var span = $('span.price', header);
				expect(span.length).toEqual(1);
				expect(span.text()).toEqual('$36.50'); // 10.95 + 25.55
			});

			function setupPage () {
				var template = "<div class='post-title'><h1>My Gear: Cameras</h1></div>"
										 + "<div class='post-body'>"
										 + "  <table>"
										 + "    <tr>"
										 + "		  <td><a href='http://www.google.com'>Google</a></td>"
										 + "		  <td><a href='http://www.bhphotovideo.com/1'>B&amp;H</a></td>"
										 + "		</tr>"
										 + "  </table>"
										 + "  <table>"
										 + "    <tr>"
										 + "		  <td><a href='http://www.bhphotovideo.com/2'>B&amp;H</a></td>"
										 + "		</tr>"
										 + "  </table>"
										 + "</div>";

				fixture = $(template);
				fixture.appendTo('body');

				googleLink = $('a[href=http://www.google.com]', fixture);
				bhLink1 = $('a[href=http://www.bhphotovideo.com/1]', fixture);
				bhLink2 = $('a[href=http://www.bhphotovideo.com/2]', fixture);
				header = $('.post-title h1');
			}

			function teardownPage () {
				googleLink.remove();
				bhLink1.remove();
				bhLink2.remove();
				fixture.remove();
			}
		});
	});
});
