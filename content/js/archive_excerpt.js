window.addEventListener("load", function() {
	Array.prototype.forEach.call(document.querySelectorAll("article.hentry section.entry-content"), function(content) {
		content.style.display = "block";
		content.style.overflow = "hidden";
		content.style.marginTop = "-1em";
		var fullHeight = content.clientHeight;
		content.style.maxHeight = "15em";
		if(content.clientHeight < fullHeight) {
			var showMore = document.createElement("button");
			showMore.textContent = "Show the rest…";
			showMore.style.margin = "1em 0";
			showMore.style.padding = "1em";
			showMore.style.color = "black";
			showMore.style.background = "rgba(255, 255, 255, 0.5)";
			showMore.style.borderWidth = "0";
			showMore.style.fontSize = "1em";
			showMore.style.cursor = "pointer";
			content.parentElement.insertBefore(showMore, content.nextSibling);

			showMore.addEventListener("click", function() {
				content.style.maxHeight = "";
				showMore.parentElement.removeChild(showMore);
			});
		}
	});
});
