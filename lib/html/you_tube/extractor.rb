require 'nokogiri'

module HTML
  module YouTube
  end
end

module HTML::YouTube::Extractor
  def extract_ids(html)
    doc = Nokogiri::HTML(html)

    [
      extract_a_tag_ids(doc),
      extract_iframe_tag_ids(doc),
      extract_embed_tag_ids(doc)
    ].inject(&:+).uniq
  end

  private
  def extract_youtube_ids_template(doc, tag, regex, attr)
    doc.css(tag).map { |node|
      url = node[attr]
      $1 if url && url.match(regex)
    }.compact
  end

  def extract_a_tag_ids(doc)
    extract_youtube_ids_template(
      doc,
      'a',
      /\/\/www\.youtube\.com\/watch\?v=([^&]*).*/,
      :href
    )
  end

  def extract_iframe_tag_ids(doc)
    extract_youtube_ids_template(
      doc,
      'iframe',
      /\/\/www\.youtube\.com\/embed\/([^?]*).*/,
      :src
    )
  end

  def extract_embed_tag_ids(doc)
    extract_youtube_ids_template(
      doc,
      'embed',
      /\/\/www\.youtube\.com\/v\/([^?]*).*/,
      :src
    )
  end
end
