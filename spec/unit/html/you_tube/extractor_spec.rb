require 'html/you_tube/extractor'

class DummyExtractor
end

describe HTML::YouTube::Extractor do
  let (:extractor) do
    extractor = DummyExtractor.new
    extractor.extend(HTML::YouTube::Extractor)
  end

  it { extractor.should respond_to(:extract_ids) }

  subject { @parse_result }

  describe "with normal html include youtube videos" do
    before do
      body = IO.read("./spec/data/html/you_tube/extractor.html")
      @parse_result = extractor.extract_ids(body)
    end

    its(:size) { should eq 33}
  end

  describe "with parsed html with one youtube video" do
    before do
      @parse_result = extractor.extract_ids(ONE_VIDEO_SITE)
    end

    its(:size) { should eq 1 }
  end

  describe "with parsed html without youtube videos" do
    before do
      @parse_result = extractor.extract_ids("<html><body></body></html>")
    end

    it { should be_empty }
  end

  describe "with unparsed html" do
    before do
      @parse_result = extractor.extract_ids("<html><body><div><a hre></bod")
    end

    it { should be_empty }
  end
end

ONE_VIDEO_SITE = <<-EOF
<html>
<head></head>
<body>
  <a href="http://www.youtube.com/watch?v=J2cdApvWL7U" target="_blank">http://www.youtube.com/watch?v=J2cdApvWL7U</a>
</body>
</html>
EOF
