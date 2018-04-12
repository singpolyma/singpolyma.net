window.addEventListener('load', function() {
	Array.prototype.forEach.call(document.querySelectorAll('*[data-subtome-resource]'), function(el) {
		el.addEventListener('click', function(e) {
			window.open("https://www.subtome.com/?subs/#/subscribe?resource=" + encodeURIComponent(this.dataset.subtomeResource));
			e.preventDefault();
		});
	});
});
