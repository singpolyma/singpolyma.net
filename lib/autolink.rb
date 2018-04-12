# frozen_string_literal: true

require "nokogiri"

class AutolinkFilter < Nanoc::Filter
	identifier :autolink

	AUTOLINK_SKIP = ["a", "pre", "code", "samp", "kbd", "var", "script", "blockquote", "q"].freeze

	# Based on https://github.com/tantek/cassis/blob/master/cassis.php#L117
	# CC BY-SA 3.0
	URL_PATTERN = /(?<![@:\/\.])(?<=\b)(?:(?:(?:https?:\/\/(?:(?:[!$&-.0-9;=?A-Z_a-z]|(?:\%[a-fA-F0-9]{2}))+(?:\:(?:[!$&-.0-9;=?A-Z_a-z]|(?:\%[a-fA-F0-9]{2}))+)?\@)?)?(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*\.)+(?:(?:aero|arpa|asia|a[cdefgilmnoqrstuwxz])|(?:biz|b[abdefghijmnorstvwyz])|(?:cat|com|coop|c[acdfghiklmnoruvxyz])|d[ejkmoz]|(?:edu|e[cegrstu])|f[ijkmor]|(?:gov|g[abdefghilmnpqrstuwy])|h[kmnrtu]|(?:info|int|i[delmnoqrst])|j[emop]|k[eghimnrwyz]|l[abcikrstuvy]|(?:mil|museum|m[acdeghklmnopqrstuvwxyz])|(?:name|net|n[acefgilopruz])|(?:org|om)|(?:pro|p[aefghklmnrstwy])|qa|r[eouw]|s[abcdeghijklmnortuvyz]|(?:tel|travel|t[cdfghjklmnoprtvwz])|u[agkmsyz]|v[aceginu]|w[fs]|y[etu]|z[amw]))|(?:(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[0-9])\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[0-9])\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[0-9])))(?:\:\d{1,5})?)(?:\/(?:(?:(?:[!#&-;=?-Z_a-z~])|(?:\%[a-fA-F0-9]{2}))*)(?:(?:[!#&\*\+\-\/0-:=@-Z_a-z~])|(?:\%[a-fA-F0-9]{2})))?)(?=\b|\s|$)/

	AUTOLINK_PATTERNS = {
		/(?<!\w|\/|\?)#[\.\-\/:_a-zA-Z0-9]*[a-zA-Z][\.\-\/:_a-zA-Z0-9]*[a-zA-Z0-9]/ => :autolink_hashtag,
		/(?<!\w|\/|\?)@[\.\-\/:__a-zA-Z0-9]+/ => :autolink_atreply,
		URL_PATTERN => :autolink_url
	}.freeze

	def run(content, params)
		tags = []

		doc = AUTOLINK_PATTERNS.reduce(Nokogiri::HTML::DocumentFragment.parse(content)) do |doc, (pattern, callback)|
			doc.traverse do |node|
				if node.name == "text" && !AUTOLINK_SKIP.any? { |tag| node.ancestors.any? { |up| up.name == tag } }
					replacement = node.to_xhtml.gsub(pattern) do |txt|
						tags << txt[1..-1] if params[:extract_hashtags] && callback == :autolink_hashtag
						send(callback, txt)
					end
					node.replace(Nokogiri::HTML::DocumentFragment.parse(replacement))
				end
			end

			doc
		end

		params[:extract_hashtags] ? tags : doc.to_xhtml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XHTML)
	end

	def matched_to_url(url)
		if URI.parse(url).scheme.nil?
			"http://#{url}"
		else
			url
		end
	end

	def autolink_url(url)
		"<a href=\"#{matched_to_url(url)}\">#{h url}</a>"
	end

	def autolink_hashtag(tag)
		tag = tag[1..-1]
		"#<a rel=\"tag\" href=\"#{@config&.[](:base_url)}/tags/#{u Unicode::downcase(tag)}\">#{h tag}</a>"
	end

	def autolink_atreply(user)
		user = user[1..-1]
		if user =~ URL_PATTERN
			"@<a class=\"u-category h-card\" href=\"#{h matched_to_url(user)}\">#{h user.sub(/^https?:\/\//, '')}</a>"
		else
			"@<a class=\"u-category h-card\" href=\"https://twitter.com/#{u user}\">#{h user}</a>"
		end
	end
end
