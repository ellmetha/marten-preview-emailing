require "./spec_helper"

describe MartenPreviewEmailing::EmailDeleteHandler do
  describe "#post" do
    it "deletes a collected email and redirects to the list" do
      preview_backend.deliver(MartenPreviewEmailing::EmailDeleteHandlerSpec::TestEmail.new)
      id = preview_directory.basename

      url = Marten.routes.reverse("preview_emailing:delete", id: id)
      response = Marten::Spec.client.post(url)

      response.status.should eq(302)
      response.headers["Location"].should eq("/emails")
      MartenPreviewEmailing::PreviewEmail.find(MartenPreviewEmailing.emails_location, id).should be_nil
    end

    it "returns a 404 response when the email does not exist" do
      url = Marten.routes.reverse("preview_emailing:delete", id: "unknown")

      expect_raises(Marten::HTTP::Errors::NotFound) do
        Marten::Spec.client.post(url)
      end
    end
  end
end

module MartenPreviewEmailing::EmailDeleteHandlerSpec
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
end
