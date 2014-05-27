def full_title(page_title)
  base_title = "YouTube Extractor"
  if page_title.empty?
    base_title
  else
    "#{base_title} | #{page_title}"
  end
end

def random_string(n = 8)
  ('a'...'z').to_a.sample(n).join
end
