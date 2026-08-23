require "./spec_helper"

describe MartenPreviewEmailing::PreviewEmail do
  describe ".valid_id?" do
    it "returns true for safe identifiers" do
      MartenPreviewEmailing::PreviewEmail.valid_id?("1787335461_60241_b7948655").should be_true
    end

    it "returns false for unsafe identifiers" do
      MartenPreviewEmailing::PreviewEmail.valid_id?("../secret").should be_false
    end
  end

  describe ".all" do
    it "returns preview emails from the configured location by default" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmail.new)

      emails = MartenPreviewEmailing::PreviewEmail.all
      emails.size.should eq(1)
      emails.first.subject.should eq("Hello World!")
    end
  end

  describe ".find" do
    it "returns nil when the identifier is unsafe" do
      MartenPreviewEmailing::PreviewEmail.find(MartenPreviewEmailing.emails_location, "../secret").should be_nil
    end
  end

  describe ".collect" do
    it "writes HTML and text previews for a simple email" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmail.new)

      directory = preview_directory
      File.exists?(directory.join("rich.html")).should be_true
      File.exists?(directory.join("plain.html")).should be_true

      html = File.read(directory.join("rich.html"))
      html.should contain("Hello World!")
      html.should contain("webmaster@localhost")
      html.should contain("test@example.com")
      html.should contain("HTML body")
      html.should contain("View plain text version")

      text = File.read(directory.join("plain.html"))
      text.should contain("Hello World!")
      text.should contain("Text body")
      text.should contain("View HTML version")
    end

    it "HTML-escapes the email body in the HTML preview" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmailWithHtmlTags.new)

      html = File.read(preview_directory.join("rich.html"))
      html.should contain("&lt;p&gt;Hello &lt;strong&gt;World&lt;/strong&gt;&lt;/p&gt;")
    end

    it "writes only a text preview when the email has no HTML body" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmailTextOnly.new)

      directory = preview_directory
      File.exists?(directory.join("plain.html")).should be_true
      File.exists?(directory.join("rich.html")).should be_false

      File.read(directory.join("plain.html")).should contain("Text body")
    end

    it "writes only an HTML preview when the email has no text body" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmailHtmlOnly.new)

      directory = preview_directory
      File.exists?(directory.join("rich.html")).should be_true
      File.exists?(directory.join("plain.html")).should be_false

      File.read(directory.join("rich.html")).should contain("HTML body")
    end

    it "writes a text preview when the email has no body" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::EmptyEmail.new)

      directory = preview_directory
      File.exists?(directory.join("plain.html")).should be_true
      File.exists?(directory.join("rich.html")).should be_false
    end

    it "includes CC addresses in the preview" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmailWithCc.new)

      File.read(preview_directory.join("plain.html")).should contain("cc1@example.com, cc2@example.com")
    end

    it "includes BCC addresses in the preview" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmailWithBcc.new)

      File.read(preview_directory.join("plain.html")).should contain("bcc1@example.com, bcc2@example.com")
    end

    it "includes the reply-to address in the preview" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmailWithReplyTo.new)

      File.read(preview_directory.join("plain.html")).should contain("reply-to@example.com")
    end

    it "includes custom headers in the preview" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmailWithHeaders.new)

      html = File.read(preview_directory.join("plain.html"))
      html.should contain("X-Custom")
      html.should contain("custom-value")
    end

    it "writes attachments next to the preview and links to them" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmailWithAttachment.new)

      directory = preview_directory
      File.read(directory.join("attachments/test_attachment.txt")).should eq("Attachment content")

      html = File.read(directory.join("rich.html"))
      html.should contain("test_attachment.txt")
      html.should contain("attachments/test_attachment.txt")
    end

    it "turns URLs into links in the text preview" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmailWithUrl.new)

      File.read(preview_directory.join("plain.html")).should contain(
        %(<a href="https://example.com/welcome">https://example.com/welcome</a>)
      )
    end

    it "stores each collected email in its own directory" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmail.new)
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmail.new)

      Dir.children(MartenPreviewEmailing.emails_location.to_s).size.should eq(2)
    end

    it "writes metadata and raw bodies used by the preview handlers" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmail.new)

      directory = preview_directory
      File.exists?(directory.join("meta.json")).should be_true
      File.exists?(directory.join("body.html")).should be_true
      File.exists?(directory.join("body.txt")).should be_true
    end
  end

  describe "#delete" do
    it "removes the preview email directory from disk" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmail.new)
      email = MartenPreviewEmailing::PreviewEmail.all.first

      email.delete

      Dir.exists?(email.directory).should be_false
      MartenPreviewEmailing::PreviewEmail.find(MartenPreviewEmailing.emails_location, email.id).should be_nil
    end
  end

  describe ".delete_all" do
    it "removes all preview emails from disk" do
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmail.new)
      preview_backend.deliver(MartenPreviewEmailing::PreviewEmailSpec::TestEmail.new)

      MartenPreviewEmailing::PreviewEmail.delete_all

      MartenPreviewEmailing::PreviewEmail.all.should be_empty
    end
  end
end

module MartenPreviewEmailing::PreviewEmailSpec
  class EmptyEmail < Marten::Email
  end

  class TestEmail < Marten::Email
    subject "Hello World!"
    to "test@example.com"

    def html_body
      "HTML body"
    end

    def text_body
      "Text body"
    end
  end

  class TestEmailHtmlOnly < Marten::Email
    subject "Hello World!"
    to "test@example.com"

    def html_body
      "HTML body"
    end
  end

  class TestEmailTextOnly < Marten::Email
    subject "Hello World!"
    to "test@example.com"

    def text_body
      "Text body"
    end
  end

  class TestEmailWithHtmlTags < TestEmail
    def html_body
      "<p>Hello <strong>World</strong></p>"
    end
  end

  class TestEmailWithCc < TestEmail
    cc ["cc1@example.com", "cc2@example.com"]
  end

  class TestEmailWithBcc < TestEmail
    bcc ["bcc1@example.com", "bcc2@example.com"]
  end

  class TestEmailWithReplyTo < TestEmail
    reply_to "reply-to@example.com"
  end

  class TestEmailWithHeaders < TestEmail
    def headers
      {"X-Custom" => "custom-value"}
    end
  end

  class TestEmailWithAttachment < TestEmail
    def initialize
      attach(IO::Memory.new("Attachment content"), filename: "test_attachment.txt")
    end
  end

  class TestEmailWithUrl < Marten::Email
    subject "Hello World!"
    to "test@example.com"

    def text_body
      "Visit https://example.com/welcome for more details."
    end
  end
end
