require "./spec_helper"

describe MartenPreviewEmailing::EmailDetailHandler do
  describe "#get" do
    it "renders a collected email" do
      preview_backend.deliver(MartenPreviewEmailing::EmailDetailHandlerSpec::TestEmail.new)
      id = preview_directory.basename

      url = Marten.routes.reverse("preview_emailing:detail", id: id)
      response = Marten::Spec.client.get(url)

      response.status.should eq(200)
      response.content.should contain("Hello World!")
      response.content.should contain("HTML body")
      response.content.should contain("View plain text version")
      response.content.should contain("/emails")
      response.content.should contain("Delete")
    end

    it "renders the plain text version when requested" do
      preview_backend.deliver(MartenPreviewEmailing::EmailDetailHandlerSpec::TestEmail.new)
      id = preview_directory.basename

      url = Marten.routes.reverse("preview_emailing:detail", id: id)
      response = Marten::Spec.client.get(url, query_params: {"part" => "plain"})

      response.status.should eq(200)
      response.content.should contain("Text body")
      response.content.should contain("View HTML version")
    end

    it "HTML-escapes the email body" do
      preview_backend.deliver(MartenPreviewEmailing::EmailDetailHandlerSpec::TestEmailWithHtmlTags.new)
      id = preview_directory.basename

      url = Marten.routes.reverse("preview_emailing:detail", id: id)
      response = Marten::Spec.client.get(url)

      response.content.should contain("&lt;p&gt;Hello &lt;strong&gt;World&lt;/strong&gt;&lt;/p&gt;")
    end

    it "returns a 404 response when the email does not exist" do
      url = Marten.routes.reverse("preview_emailing:detail", id: "unknown")

      expect_raises(Marten::HTTP::Errors::NotFound) do
        Marten::Spec.client.get(url)
      end
    end

    it "returns a 404 response when the identifier is unsafe" do
      url = Marten.routes.reverse("preview_emailing:detail", id: "foo..bar")

      expect_raises(Marten::HTTP::Errors::NotFound) do
        Marten::Spec.client.get(url)
      end
    end
  end
end

module MartenPreviewEmailing::EmailDetailHandlerSpec
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

  class TestEmailWithHtmlTags < TestEmail
    def html_body
      "<p>Hello <strong>World</strong></p>"
    end
  end
end
