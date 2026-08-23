module MartenPreviewEmailing
  # Displays a single preview email.
  class EmailDetailHandler < Marten::Handlers::Template
    template_name "marten_preview_emailing/email_detail.html"

    before_render :add_email_to_context

    private def add_email_to_context : Nil
      email = preview_email
      html = show_html?(email)

      context[:email] = email
      context[:html] = html
      context[:body] = email.preview_body(html)
    end

    private def preview_email : PreviewEmail
      email = PreviewEmail.find(MartenPreviewEmailing.emails_location, params["id"].to_s)
      raise Marten::HTTP::Errors::NotFound.new("Email not found") if email.nil?
      email
    end

    private def show_html?(email : PreviewEmail) : Bool
      return false unless email.has_html?
      return true unless email.has_text?

      request.query_params["part"]? != "plain"
    end
  end
end
