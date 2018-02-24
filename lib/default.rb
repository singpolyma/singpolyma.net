require "auto_paragraph"
require "babosa"
require "new_base_60"
require "uri"
require "active_support/inflector/methods"

include Nanoc::Helpers::LinkTo
include Nanoc::Helpers::Text
include Nanoc::Helpers::Rendering
include ActiveSupport::Inflector

ENV['TZ'] = 'UTC'

Nanoc::Filter.define(:autop) do |content, _params|
	AutoParagraph.new(insert_line_breaks: true).execute(content.dup)
end

$posts = {}
def posts(*kinds)
	patterns = kinds.map { |kind| /^\/#{kind}\/[^\/]+\/index/ }

	$posts[kinds] ||= @items
		.select { |item|
			patterns.any? { |pattern| item.identifier.to_s =~ pattern }
		}
		.sort { |a, b| b[:date] <=> a[:date] }
end

def articles
	posts "articles"
end

def notes
	posts "notes"
end

def all_posts
	posts "articles", "notes"
end

def char_for_kind(kind)
	case kind
	when :article, :articles
		'p'
	when :note, :notes
		't'
	else
		raise "Unknown kind: #{kind}"
	end
end

$day_index = {}
def day_index(post)
	$day_index[post.identifier] ||= send(post_kind(post, plural: true))
		.select { |x| x[:date].to_date == post[:date].to_date }
		.sort_by { |x| x[:date] }
		.index(post)
end

def post_kind(post, plural: false)
	kind = post.identifier.components[0]
	(plural ? kind : singularize(kind)).to_sym
end

def shortid(post)
	char = char_for_kind(post_kind(post))
	id = "#{char}#{post[:date].to_date.to_sxg}#{day_index(post).to_sxgf}"
	raise "Bad shortid generated: #{shortid}" unless id.length == 5
	id
end

def u(s)
	URI.escape(s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

class Time
	def frac_day
		hour.to_r/24 + min.to_r/1440 + sec.to_r/86400
	end

	def jtime
		strftime("%Y-%j") + ("%.3f" % frac_day)[1..-1] + "Z"
	end
end
