# frozen_string_literal: true

require "auto_paragraph"
require "babosa"
require "new_base_60"
require "uri"
require "active_support/inflector/methods"
require "base64"
require "tilt"
require "slim"
require "unicode"

include Nanoc::Helpers::LinkTo
include Nanoc::Helpers::Text
include Nanoc::Helpers::Rendering
include ActiveSupport::Inflector

ENV['TZ'] = 'UTC'

Tilt.prefer Tilt::KramdownTemplate
Slim::Embedded.options[:markdown] = { auto_ids: false }

Nanoc::Filter.define(:autop) do |content, _params|
	AutoParagraph.new(insert_line_breaks: true).execute(content.dup)
end

Nanoc::Filter.define(:clean_indents) do |content, _params|
	content.gsub(/^\s+$/, "\n").gsub(/^(\t*)(  )+/) { |match| $~[1] + "\t" * ($~.to_a.length - 2) }
end

$posts = {}
def posts(*kinds)
	patterns = "{#{kinds.join(",")}}"

	$posts[[kinds, @items.first.class]] ||= @items.find_all("/#{patterns}/*/index.*")
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

$year_index = {}
def by_year(posts)
	$year_index[[posts, @items.first.class]] ||= send(posts).group_by { |post| post[:date].year }
end

$tag_index = {}
def by_tag(posts)
	$tag_index[[posts, @items.first.class]] ||= send(posts).each_with_object(Hash.new { |h, k| h[k] = [] }) { |post, h|
		Array(post[:tags]).each { |tag| h[Unicode::downcase(tag)] << post }
	}
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
	kind = post_kind(post, plural: true)

	$day_index[kind] ||= send(kind)
		.reverse
		.group_by { |x| x[:date].to_date }

	$day_index[kind][post[:date].to_date].index(post)
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
